// SPDX-License-Identifier: MIT
// 指定使用 MIT 许可证

// 规定 Solidity 编译器版本需在 0.8.0 及以上且低于 0.9.0
pragma solidity ^0.8.0;

// 从 OpenZeppelin 库导入 ERC20 合约标准实现
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleToken
 * @dev 简单 ERC20 代币合约，部署时为创建者铸币
 * 可修改币名、简称、初始铸币量
 */
contract SimpleToken is ERC20 {
    /**
     * @dev 合约构造函数，部署时执行
     * 修改说明：
     * - 币名：修改 ERC20("SimpleToken", "STK") 中第一个参数
     * - 简称：修改 ERC20("SimpleToken", "STK") 中第二个参数
     * - 初始铸币量：修改 _mint 第二个参数中的数字
     */
    constructor() ERC20("SimpleToken", "STK") {
        // 为合约创建者铸造 10000 个代币
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}