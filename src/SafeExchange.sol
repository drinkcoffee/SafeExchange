// SPDX-License-Identifier: BSD
// Use 0.7.6 to be compatible with Open Zeppelin 3.4.0
pragma solidity ^0.7.6;

import "./oz340/AccessControl.sol";

/**
 * SafeExchange allows a contract with AccessControl to be sold. The contract is 
 * deployed by the buyer. The seller then calls the exchange function.
 */
contract SafeExchange {
    // The only admin role of the contract. All other roles, if they exist, 
    // should be revoked.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Owner of the contract.
    address public owner;

    // Administrator that will have DEFAULT_ADMIN_ROLE after the exchange.
    address public newAdmin;

    // Contract that is to be exchanged
    AccessControl public contractForSale;

    // Exchange completed, allowing for additional payment.
    address public exchangeCompletedBySeller;

    // Emitted when the exchange has been completed.
    event Exchanged(address seller);

    // Modifier to only allow the owner to execute a function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /** 
     * @notice Buyer creates the contract, sending the offered amount.
     * @param _newAdmin Administrator to be given sole ownership on completion of the sale.
     * @param _contractForSale The contract which is to be bought.
     */
    constructor(address _newAdmin, address _contractForSale) payable {
        owner = msg.sender;
        newAdmin = _newAdmin;
        contractForSale = AccessControl(_contractForSale);
    }

    /** 
     * @notice Seller calls this, to exchange control of admin rights for the balance of this contract.
     * @dev The transaction must be sent by the account with DEFAULT ADMIN on the contract to be sold.
     * @param _expectedAmountInEth The expected sale price. This is needed to mitigate front running. 
     *     That is, the balance of this contract changing immediately prior to this function being called.
     */
    function exchange(uint256 _expectedAmountInEth) external {
        // Prevent contract accounts calling this. This prevents MultiCall contracts possibly 
        // doing something "extra" in the same transaction.
        require(msg.sender == tx.origin, "Not an EOA");

        // Ensure the seller doesn't front run this transaction reducing the amount offered
        uint256 price1 = price();
        uint256 amount = _expectedAmountInEth * 1 ether;
        require(amount <= price1, "Insufficient funds");

        // Check that the number of admins is 1. The issue that we are guarding against is there being 
        // two DEFAULT_ADMIN_ROLE, of which only one is revoked.
        // NOTE: If there other classes of admins, they should be revoked prior to this call.
        // This revocation is not checked for in this code.
        uint256 numAdmins = contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(numAdmins == 1, "Too many admins");

        // Grant role DEFAULT_ADMIN_ROLE to the newAdmin.
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        // Renounce DEFAULT_ADMIN_ROLE role for msg.sender
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Send price to msg.sender
        transferMoney(msg.sender, price1);

        // Indicate that the seller could receive a further future reward.
        exchangeCompletedBySeller = msg.sender;

        // Indicate exchange complted.
        emit Exchanged(msg.sender);
    }

    /**
     * @notice Pay a bonus payment to the seller.
     * @dev For this to work, the increaseOffer funcion needs to be called 
     *      to add value to the contract.
     */
    function payBonusPayment() external onlyOwner() {
        transferMoney(exchangeCompletedBySeller, price());
    }


    /**
     * @notice Buyer calls this function to increase the offer.
     */
    function increaseOffer() external payable onlyOwner() {
    }

    /**
     * @notice Buyer calls this function to decrease the offer.
     * @param _amountInEther Amount to decrease in Ether.
     */
    function decreaseOffer(uint256 _amountInEther) external payable onlyOwner() {
        uint256 amount = _amountInEther * 1 ether;
        transferMoney(msg.sender, amount);
    }

    /**
     * @notice Send all money to the owner and delete the contract
     */
    function goodBye() external onlyOwner {
        selfdestruct(payable(owner));
    }

    /**
     * @notice Price is the amount being offered for the admin account
     * @return bal The balance of this contract.
     */
    function price() public view returns (uint256 bal) {
        bal = address(this).balance;
    }

    /**
     * @notice Transfer money.
     * @param _to Recipient of the ether.
     * @param _amount Amount to transfer in wei.
     */
    function transferMoney(address _to, uint256 _amount) private {
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}