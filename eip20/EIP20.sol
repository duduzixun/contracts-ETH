// SPDX-License-Identifier: MIT
// 指定合约的开源许可协议为 MIT
pragma solidity ^0.8.0;
// 指定 Solidity 编译器版本，要求版本大于等于 0.8.0 且小于 0.9.0

// 导入 EIP20 接口文件，该接口定义了 EIP20 标准代币合约需要实现的函数
import "./EIP20Interface.sol";
// 导入 OpenZeppelin 的防重入攻击保护库，用于防止重入攻击
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// 导入 OpenZeppelin 的访问控制库，提供合约所有权管理功能
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Enhanced EIP20 代币合约
 * @dev 完整实现 EIP20 标准，包含铸造/销毁功能、安全授权操作和供应量控制
 */
contract EIP20 is EIP20Interface, ReentrancyGuard, Ownable {
    // 代币名称，对外公开可查看
    string public name;
    // 代币的小数位数，对外公开可查看
    uint8 public decimals;
    // 代币符号，对外公开可查看
    string public symbol;
    // 代币的总供应量，对外公开可查看
    uint256 public totalSupply;

    // 公开的最大供应量常量，代币的总供应量不能超过此值
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18;

    // 记录每个地址的代币余额，使用映射存储，键为地址，值为余额
    mapping (address => uint256) private balances;
    // 记录授权情况，外层映射键为代币所有者地址，内层映射键为被授权地址，值为授权的代币数量
    mapping (address => mapping (address => uint256)) private allowed;

    // 定义代币销毁事件，当有代币被销毁时触发
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev 合约构造函数，用于初始化代币信息
     * @param _initialAmount 初始代币供应量
     * @param _tokenName 代币名称
     * @param _decimalUnits 代币的小数位数
     * @param _tokenSymbol 代币符号
     */
    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) Ownable(msg.sender) {
        // 确保初始供应量是一个正数
        require(_initialAmount > 0, "EIP20: Initial supply must be positive");
        // 确保初始供应量不超过最大允许供应量
        require(_initialAmount <= MAX_SUPPLY, "EIP20: Exceeds max supply");
        // 确保小数位数不超过最大限制 18
        require(_decimalUnits <= 18, "EIP20: Decimals exceed limit");
        // 确保代币名称不为空
        require(bytes(_tokenName).length > 0, "EIP20: Name required");
        // 确保代币符号不为空
        require(bytes(_tokenSymbol).length > 0, "EIP20: Symbol required");

        // 将初始供应量分配给合约部署者
        balances[msg.sender] = _initialAmount;
        // 设置总供应量
        totalSupply = _initialAmount;
        // 设置代币名称
        name = _tokenName;
        // 设置小数位数
        decimals = _decimalUnits;
        // 设置代币符号
        symbol = _tokenSymbol;

        // 触发初始转账事件，从地址 0 转账到合约部署者地址
        emit Transfer(address(0), msg.sender, _initialAmount);
    }

    // ======================== 核心功能 ========================
    /**
     * @dev 从当前调用者地址向指定地址转账代币
     * @param _to 接收代币的地址
     * @param _value 转账的代币数量
     * @return 转账是否成功，始终返回 true
     */
    function transfer(address _to, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        // 确保转账数量大于零
        require(_value > 0, "EIP20: Zero transfer");
        // 调用内部转账函数进行转账操作
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 从指定地址向另一个指定地址转账代币，前提是调用者已经被授权
     * @param _from 转出代币的地址
     * @param _to 接收代币的地址
     * @param _value 转账的代币数量
     * @return 转账是否成功，始终返回 true
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        // 获取调用者被授权使用的代币数量
        uint256 currentAllowance = allowed[_from][msg.sender];
        // 确保转账数量不超过授权数量
        require(currentAllowance >= _value, "EIP20: Allowance exceeded");
        // 确保转出地址有足够的余额
        require(balances[_from] >= _value, "EIP20: Insufficient balance");

        // 减少授权数量
        allowed[_from][msg.sender] = currentAllowance - _value;
        // 触发授权更新事件
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);

        // 调用内部转账函数进行转账操作
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev 查询指定地址的代币余额
     * @param _owner 查询余额的地址
     * @return 该地址的代币余额
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // ====================== 授权管理 ======================
    /**
     * @dev 授权指定地址使用调用者的代币
     * @param _spender 被授权的地址
     * @param _value 授权的代币数量
     * @return 授权是否成功，始终返回 true
     */
    function approve(address _spender, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        // 调用内部授权函数进行授权操作
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 增加对指定地址的授权额度
     * @param _spender 被授权的地址
     * @param _addedValue 增加的授权代币数量
     * @return 操作是否成功，始终返回 true
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        nonReentrant
        returns (bool)
    {
        // 调用内部授权函数更新授权额度
        _approve(msg.sender, _spender, allowed[msg.sender][_spender] + _addedValue);
        return true;
    }

    /**
     * @dev 减少对指定地址的授权额度
     * @param _spender 被授权的地址
     * @param _subtractedValue 减少的授权代币数量
     * @return 操作是否成功，始终返回 true
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        nonReentrant
        returns (bool)
    {
        // 获取当前的授权额度
        uint256 currentAllowance = allowed[msg.sender][_spender];
        // 确保减少的额度不超过当前授权额度
        require(currentAllowance >= _subtractedValue, "EIP20: Underflow");
        // 调用内部授权函数更新授权额度
        _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }

    /**
     * @dev 查询指定地址对另一个指定地址的授权数量
     * @param _owner 授权的地址
     * @param _spender 被授权的地址
     * @return 剩余的授权数量
     */
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    // ====================== 供应量管理 ======================
    /**
     * @dev 增发代币，增加总供应量，只有合约所有者可以调用
     * @param _to 接收增发代币的地址
     * @param _amount 增发的代币数量
     */
    function mint(address _to, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        // 确保增发后的总供应量不超过最大允许供应量
        require(totalSupply + _amount <= MAX_SUPPLY, "EIP20: Cap exceeded");
        // 增加总供应量
        totalSupply += _amount;
        // 增加接收地址的余额
        balances[_to] += _amount;
        // 触发转账事件，从地址 0 转账到接收地址
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev 销毁代币，减少总供应量
     * @param _amount 销毁的代币数量
     */
    function burn(uint256 _amount)
        public
        nonReentrant
    {
        // 确保调用者有足够的余额进行销毁
        require(balances[msg.sender] >= _amount, "EIP20: Insufficient balance");
        // 减少调用者的余额
        balances[msg.sender] -= _amount;
        // 减少总供应量
        totalSupply -= _amount;
        // 触发转账事件，从调用者地址转账到地址 0
        emit Transfer(msg.sender, address(0), _amount);
        // 触发代币销毁事件
        emit Burn(msg.sender, _amount);
    }

    // ====================== 内部函数 ======================
    /**
     * @dev 内部转账函数，用于执行实际的转账操作
     * @param _from 转出代币的地址
     * @param _to 接收代币的地址
     * @param _value 转账的代币数量
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
        // 确保转出地址不是零地址
        require(_from != address(0), "EIP20: From zero address");
        // 确保接收地址不是零地址
        require(_to != address(0), "EIP20: To zero address");

        // 减少转出地址的余额
        balances[_from] -= _value;
        // 增加接收地址的余额
        balances[_to] += _value;
        // 触发转账事件
        emit Transfer(_from, _to, _value);
    }

    /**
     * @dev 内部授权函数，用于执行实际的授权操作
     * @param _owner 授权的地址
     * @param _spender 被授权的地址
     * @param _amount 授权的代币数量
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        // 确保授权地址不是零地址
        require(_owner != address(0), "EIP20: Approve from zero");
        // 确保被授权地址不是零地址
        require(_spender != address(0), "EIP20: Approve to zero");

        // 设置授权数量
        allowed[_owner][_spender] = _amount;
        // 触发授权事件
        emit Approval(_owner, _spender, _amount);
    }
}