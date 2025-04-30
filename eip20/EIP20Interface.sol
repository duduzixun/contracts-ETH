// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.8.0;

/**
 * @title EIP20Interface
 * @dev 定义 EIP20（ERC20）代币标准的接口。
 */
interface EIP20Interface {
    /**
     * @dev 代币的总供应量。
     */
    uint256 public totalSupply;

    /**
     * @dev 获取指定账户的代币余额。
     * @param _owner 要查询余额的账户地址。
     * @return 该账户的代币余额。
     */
    function balanceOf(address _owner) external view returns (uint256 balance);

    /**
     * @dev 从消息发送者的账户向指定账户转移代币。
     * @param _to 接收代币的账户地址。
     * @param _value 要转移的代币数量。
     * @return 转移是否成功。
     */
    function transfer(address _to, uint256 _value) external returns (bool success);

    /**
     * @dev 从指定账户向另一个账户转移代币，前提是消息发送者已获得授权。
     * @param _from 发送代币的账户地址。
     * @param _to 接收代币的账户地址。
     * @param _value 要转移的代币数量。
     * @return 转移是否成功。
     */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /**
     * @dev 消息发送者授权指定账户花费一定数量的代币。
     * @param _spender 被授权可以转移代币的账户地址。
     * @param _value 被授权转移的代币数量。
     * @return 授权是否成功。
     */
    function approve(address _spender, uint256 _value) external returns (bool success);

    /**
     * @dev 查询指定账户对另一个账户的授权额度。
     * @param _owner 拥有代币的账户地址。
     * @param _spender 被授权可以转移代币的账户地址。
     * @return 剩余允许花费的代币数量。
     */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    /**
     * @dev 代币转移事件。
     * @param _from 发送代币的账户地址。
     * @param _to 接收代币的账户地址。
     * @param _value 转移的代币数量。
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev 授权事件。
     * @param _owner 拥有代币的账户地址。
     * @param _spender 被授权可以转移代币的账户地址。
     * @param _value 授权转移的代币数量。
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}    