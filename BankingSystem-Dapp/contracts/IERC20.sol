// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

 

     function getBankOwner() external view returns (address);

    

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}







// function checkClientOrNOt(address _clientAddress)
    //     external
    //     view
    //     returns (bool);

    // function getBranchAddress(uint256 _enterBranchNum)
    //     external
    //     view
    //     returns (address);

    // function getClientAddress(uint256 _enterClientID, uint256 _branchNum)
    //     external
    //     view
    //     returns (address);

    // function getCountOfBranch() external view returns (uint256);

    // function getBranchNum() external view returns (uint256);

    // function getBranchNumForClient()
    //     external
    //     view
    //     returns (uint256 branchNumber);

    //function getBranchAddress(uint256 _enterBranchNum)external view returns(address);