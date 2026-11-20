// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24521896. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract StakingPool_1896 {
    address public owner;
    mapping(address => uint256) public credit;
    IERC20Like public rewardToken;
    mapping(address => uint256) public tokenCredit;
    bool private mutex;
    mapping(address => uint256) public escrowed;
    mapping(bytes32 => bool) public claimedKeys;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    modifier exclusive() {
        require(!mutex, "reentrant");
        mutex = true;
        _;
        mutex = false;
    }

    constructor() {
        owner = msg.sender;
    }

    function fund() external payable {
        credit[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function sweep(address payable to) external onlyOwner {
        require(to != address(0), "zero");
        (bool ok, ) = to.call{value: address(this).balance}("");
        require(ok, "sweep failed");
    }

    function setPayToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        rewardToken = IERC20Like(t);
    }

    function withdrawToken(uint256 amount) external {
        require(tokenCredit[msg.sender] >= amount, "not enough");
        tokenCredit[msg.sender] -= amount;
        require(rewardToken.transfer(msg.sender, amount), "token transfer failed");
    }

    function setAdmin(address newOwner) external {
        require(msg.sender == owner, "not owner");
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function fundSafe() external payable exclusive {
        escrowed[msg.sender] += msg.value;
    }

    function claimSafe() external exclusive {
        uint256 a = escrowed[msg.sender];
        escrowed[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }

    function weekdayIndex() external view returns (uint256) {
        // Chi dung de HIEN THI thu trong tuan; khong lam nguon ngau nhien, khong quyet dinh quyen/tien.
        // slither-disable-next-line weak-prng
        return (block.timestamp / 1 days + 4) % 7;
    }

    function useCode(string calldata campaign, string calldata code) external {
        bytes32 id = keccak256(abi.encode(campaign, code));
        require(!claimedKeys[id], "used");
        claimedKeys[id] = true;
        credit[msg.sender] += 1;
    }
}
