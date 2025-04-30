// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./EIP20Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Enhanced EIP20 代币合约
 * @dev 完整实现EIP20标准，包含铸造/销毁功能、安全授权操作和供应量控制
 */
contract EIP20 is EIP20Interface, ReentrancyGuard, Ownable {
    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 private _totalSupply; // 定义一个私有变量来存储总供应量
    uint256 public constant MAX_SUPPLY = 1000000 * 10**18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;
    event Burn(address indexed burner, uint256 value);

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) Ownable(msg.sender) {
        require(_initialAmount > 0, "EIP20: Initial supply must be positive");
        require(_initialAmount <= MAX_SUPPLY, "EIP20: Exceeds max supply");
        require(_decimalUnits <= 18, "EIP20: Decimals exceed limit");
        require(bytes(_tokenName).length > 0, "EIP20: Name required");
        require(bytes(_tokenSymbol).length > 0, "EIP20: Symbol required");
        balances[msg.sender] = _initialAmount;
        _totalSupply = _initialAmount; // 使用私有变量
        name = _tokenName;
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
        emit Transfer(address(0), msg.sender, _initialAmount);
    }

    // 实现接口中的 totalSupply 函数
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // ======================== 核心功能 ========================
    /**
     * @dev 从当前调用者地址向指定地址转账代币
     * @param _to 接收代币的地址
     * @param _value 转账的代币数量
     * @return 转账是否成功，始终返回true
     */
    function transfer(address _to, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        require(_value > 0, "EIP20: Zero transfer");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev 从指定地址向另一个指定地址转账代币，前提是调用者已经被授权
     * @param _from 转出代币的地址
     * @param _to 接收代币的地址
     * @param _value 转账的代币数量
     * @return 转账是否成功，始终返回true
     */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        uint256 currentAllowance = allowed[_from][msg.sender];
        require(currentAllowance >= _value, "EIP20: Allowance exceeded");
        require(balances[_from] >= _value, "EIP20: Insufficient balance");
        allowed[_from][msg.sender] = currentAllowance - _value;
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
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
     * @return 授权是否成功，始终返回true
     */
    function approve(address _spender, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        _approve(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev 增加对指定地址的授权额度
     * @param _spender 被授权的地址
     * @param _addedValue 增加的授权代币数量
     * @return 操作是否成功，始终返回true
     */
    function increaseAllowance(address _spender, uint256 _addedValue)
        public
        nonReentrant
        returns (bool)
    {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender] + _addedValue);
        return true;
    }

    /**
     * @dev 减少对指定地址的授权额度
     * @param _spender 被授权的地址
     * @param _subtractedValue 减少的授权代币数量
     * @return 操作是否成功，始终返回true
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue)
        public
        nonReentrant
        returns (bool)
    {
        uint256 currentAllowance = allowed[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "EIP20: Underflow");
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
        require(_totalSupply + _amount <= MAX_SUPPLY, "EIP20: Cap exceeded");
        _totalSupply += _amount;
        balances[_to] += _amount;
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
        require(balances[msg.sender] >= _amount, "EIP20: Insufficient balance");
        balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
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
        require(_from != address(0), "EIP20: From zero address");
        require(_to != address(0), "EIP20: To zero address");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // ##

    /**
     * @dev 内部授权函数，用于执行实际的授权操作
     * @param _owner 授权的地址
     * @param _spender 被授权的地址
     * @param _amount 授权的代币数量
     */
    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "EIP20: Approve from zero");
        require(_spender != address(0), "EIP20: Approve to zero");
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}    