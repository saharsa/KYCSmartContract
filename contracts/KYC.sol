pragma solidity ^0.5.17;

contract KYCContract {
    /*
    -------------------------------------- CONTRACT VARIABLES ----------------------------------------------------
    */

    // Customer
    struct Customer {
        string userName; //unique
        string customerData; //unique
        bool kycStatus;
        uint8 downVotes;
        uint8 upVotes;
        address bank;
    }

    // Bank
    struct Bank {
        string bankName;
        address ethAddress; //unique
        bool kycPermission;
        uint8 reports;
        uint8 kycCount;
        string regNumber; //unique
    }

    // KYC Request
    struct KYCRequest {
        string userName;
        address bank;
        string customerData; //unique
    }

    // Map of Customers by username
    mapping(string => Customer) customers;

    // Map of Banks by bankName
    mapping(address => Bank) banks;

    uint256 private bankCount;

    // Map of KYC requests by customerData
    mapping(string => KYCRequest) kycRequests;

    // Admin of the contract
    address private admin;

    constructor() public {
        admin = msg.sender;
        bankCount = 0;
    }

    /*
    -------------------------------------- MODIFIERS ----------------------------------------------------
    */

    // Checks if KYC request is new
    modifier isNewKYCRequest(string memory _customerData) {
        require(
            bytes(kycRequests[_customerData].customerData).length == 0,
            "KYC request already exists."
        );
        _;
    }

    // Checks if KYC request already exists
    modifier isExistingKYCRequest(string memory _customerData) {
        require(
            bytes(kycRequests[_customerData].customerData).length != 0,
            "KYC request doesn't exist."
        );
        _;
    }
    
    

    // Checks if Bank if allowed to perform KYC
    modifier isBankKYCEnabled(address _bankAddress) {
        require(
            banks[_bankAddress].kycPermission == false,
            "Bank is not permitted to perform KYC."
        );
        _;
    }

    // Checks if Customer already exists
    modifier isExistingCustomer(string memory _userName) {
        require(
            bytes(customers[_userName].userName).length != 0,
            "Customer does not exist."
        );
        _;
    }

    // Checks if Customer does not exist
    modifier isNewCustomer(string memory _userName) {
        require(
            bytes(customers[_userName].userName).length == 0,
            "Customer already exists."
        );
        _;
    }

    // Checks if Customer is associated with the bank
    modifier isBanksCustomer(string memory _userName) {
        require(
            customers[_userName].bank == msg.sender,
            "Customer not associated with this bank."
        );
        _;
    }

    // Checks if Customer is not associated with the bank
    modifier isNotBanksCustomer(string memory _userName) {
        require(
            customers[_userName].bank != msg.sender,
            "Customer associated with this bank."
        );
        _;
    }

    // Check if the bank exists
    modifier isExistingBank(address _bankAddress) {
        require(
            bytes(banks[_bankAddress].bankName).length != 0,
            "Bank does not exist."
        );
        _;
    }

    // Check if the bank does not exist
    modifier isNotExistingBank(address _bankAddress) {
        require(
            bytes(banks[_bankAddress].bankName).length == 0,
            "Bank already exists."
        );
        _;
    }

    // Check if the person making modifications is admin
    modifier isAdmin(address _admin) {
        require(_admin == admin, "Not authorized to perform this action.");
        _;
    }
    
    // Check if valid address
    /*modifier isValidAddress(address _bankAddress) {
        require(Web3.utils.isAddress(_bankAddress), "Not a valid address.");
        _;
    }*/

    /*
    -------------------------------------- UTILITY FUNCTIONS -----------------------------------------------------------------
    */

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function isCustomerKYCValid(
        uint256 upvotes,
        uint256 downvotes,
        uint256 totalBanks
    ) public pure returns (bool) {
        bool val = true;
        if (upvotes < downvotes) {
            val = false;
        }
        if (totalBanks >= 5 && downvotes > totalBanks / 3) {
            val = false;
        }
        return val;
    }
    
    function isBankKYCValid(
        uint256 downvotes,
        uint256 totalBanks
    ) public pure returns (bool) {
        bool val = true;
        if (totalBanks >= 5 && downvotes > totalBanks / 3) {
            val = false;
        }
        return val;
    }
    
    
    /*
    -------------------------------------- BANK INTERFACE -----------------------------------------------------------------
    */

    // Event triggered when new KYC request created
    event AddKYCRequest(address indexed Bank, string _userName);

    /**
     * Add a new KYC request
     * @param  {string} _userName Name of the customer
     * @param {string} _customerData Hash of customer's data
     */
    function addKYCRequest(string memory _userName, string memory _customerData)
        public
        isBankKYCEnabled(msg.sender)
        isNewKYCRequest(_customerData)
        returns (bool)
    {
        kycRequests[_customerData].customerData = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
        emit AddKYCRequest(msg.sender, _userName);
        return true;
    }

    // Event triggered when a KYC request is removed
    event RemoveKYCRequest(address indexed Bank, string _userName);

    /**
     * Remove a KYC request
     * @param  {string} _userName Name of the customer
     * @param {string} _customerData Hash of customer's data
     */
    function removeKYCRequest(
        string memory _userName,
        string memory _customerData
    )
        public
        isExistingKYCRequest(_customerData)
        returns (bool)
    {
        delete kycRequests[_customerData];
        emit RemoveKYCRequest(msg.sender, _userName);
        return true;
    }

    // Event triggered when a new customer is added
    event AddCustomer(address indexed Bank, string indexed _userName);

    /**
     * Add a new customer
     * @param {string} _userName Name of the customer
     * @param {string} _customerData Hash of customer's data
     */
    function addCustomer(string memory _userName, string memory _customerData)
        public
        payable
        isExistingBank(msg.sender)
        isBankKYCEnabled(msg.sender)
        isNewCustomer(_userName)
        returns (bool)
    {
        customers[_userName].userName = _userName;
        customers[_userName].customerData = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].kycStatus = true;
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
        emit AddCustomer(msg.sender, _userName);
        return true;
    }

    // Event triggered when a customer is removed
    event RemoveCustomer(address indexed Bank, string indexed _userName);

    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     */
    function removeCustomer(string memory _userName)
        public
        payable
        isExistingBank(msg.sender)
        isBankKYCEnabled(msg.sender)
        isExistingCustomer(_userName)
        isBanksCustomer(_userName)
        returns (bool)
    {
        removeKYCRequest(_userName, customers[_userName].customerData);
        delete customers[_userName];
        emit RemoveCustomer(msg.sender, _userName);
        return true;
    }

    /**
     * View customer information
     * @param  {public} _userName Name of the customer
     * @return {Customer}  The customer struct as an object
     */
    function viewCustomer(string memory _userName)
        public
        view
        isExistingCustomer(_userName)
        returns (string memory, string memory)
    {
        return (
            customers[_userName].userName,
            customers[_userName].customerData
        );
    }

    event ModifyCustomer(address indexed Bank, string indexed _userName);

    /**
     * Edit customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _newCustomerData Hash of customer's data
     */
    function modifyCustomer(
        string memory _userName,
        string memory _newCustomerData
    )
        public
        payable
        isBankKYCEnabled(msg.sender)
        isExistingCustomer(_userName)
        isBanksCustomer(_userName)
        returns (bool)
    {
        customers[_userName].customerData = _newCustomerData;
        removeKYCRequest(_userName, customers[_userName].customerData);
        customers[_userName].upVotes = 0;
        customers[_userName].downVotes = 0;
        emit ModifyCustomer(msg.sender, _userName);
        return true;
    }

    event UpvoteCustomer(address indexed Bank, string indexed _userName);

    /**
     *This function allows a bank to cast an upvote for a customer. This vote from a bank means that it accepts the customer details as well acknowledge the KYC process done by some bank on the customer.
     * @param  {string} _userName Name of the customer
     */
    function upvoteCustomer(string memory _userName)
        public
        payable
        isBankKYCEnabled(msg.sender)
        isExistingCustomer(_userName)
        isNotBanksCustomer(_userName)
        returns (bool)
    {
        customers[_userName].upVotes++;
        if (
            isCustomerKYCValid(
                customers[_userName].upVotes,
                customers[_userName].downVotes,
                bankCount
            )
        ) {
            customers[_userName].kycStatus = true;
        } else {
            customers[_userName].kycStatus = false;
        }
        if (
            isBankKYCValid(
                customers[_userName].downVotes,
                bankCount
            )
        ) {
            banks[customers[_userName].bank].kycPermission = true;
        } else {
            banks[customers[_userName].bank].kycPermission = false;
        }
        emit UpvoteCustomer(msg.sender, _userName);
        return true;
    }

    event DownvoteCustomer(address indexed Bank, string indexed _userName);

    /**
     * This function allows a bank to cast an downvote for a customer. This vote from a bank means that it does not accept the customer details.
     * @param  {string} _userName Name of the customer
     */
    function downvoteCustomer(string memory _userName)
        public
        payable
        isBankKYCEnabled(msg.sender)
        isExistingCustomer(_userName)
        isNotBanksCustomer(_userName)
        returns (bool)
    {
        customers[_userName].downVotes++;
        if (
            isCustomerKYCValid(
                customers[_userName].upVotes,
                customers[_userName].downVotes,
                bankCount
            )
        ) {
            customers[_userName].kycStatus = true;
        } else {
            customers[_userName].kycStatus = false;
        }
        if (
            isBankKYCValid(
                customers[_userName].downVotes,
                bankCount
            )
        ) {
            banks[customers[_userName].bank].kycPermission = true;
        } else {
            banks[customers[_userName].bank].kycPermission = false;
        }
        emit DownvoteCustomer(msg.sender, _userName);
        return true;
    }

    /**
     * This function is used to fetch bank reports from the smart contract
     * @param  {address} _bankAddress Address of bank
     */
    function getBankReports(address _bankAddress)
        public
        view
        isExistingBank(_bankAddress)
        returns (uint256)
    {
        return banks[_bankAddress].reports;
    }

    /**
     * This function is used to fetch customer kyc status from the smart contract. If true then the customer is verified.
     * @param  {string} _userName Name of the customer
     */
    function getCustomerStatus(string memory _userName)
        public
        view
        isExistingCustomer(_userName)
        returns (bool)
    {
        return customers[_userName].kycStatus;
    }

    /**
     * This function is used to fetch the bank details.
     * @param  {address} _bankAddress Address of bank
     */
    function getBankDetails(address _bankAddress)
        public
        view
        isExistingBank(_bankAddress)
        returns (
            string memory,
            address,
            bool,
            uint8,
            uint8,
            string memory
        )
    {
        return (
            banks[_bankAddress].bankName,
            banks[_bankAddress].ethAddress,
            banks[_bankAddress].kycPermission,
            banks[_bankAddress].reports,
            banks[_bankAddress].kycCount,
            banks[_bankAddress].regNumber
        );
    }

    /*
    -------------------------------------- ADMIN INTERFACE -----------------------------------------------------------------
    */

    event AddBank(address indexed admin, address _bankName);

    /**
     * Add a new Bank
     * @param {string} _bankName Name of the bank to be added
     * @param {string} _bankRegistrationNumber registration number of the bank to be added
     * @param {address} _bankAddress address of the bank to be added
     */
    function addBank(
        string memory _bankName,
        address _bankAddress,
        string memory _bankRegistrationNumber
    )
        public
        isAdmin(msg.sender)
        isNotExistingBank(_bankAddress)
        returns (bool)
    {
        banks[_bankAddress].bankName = _bankName;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].regNumber = _bankRegistrationNumber;
        banks[_bankAddress].kycPermission = true;
        banks[_bankAddress].reports = 0;
        banks[_bankAddress].kycCount = 0;
        bankCount++;
        emit AddBank(admin, _bankAddress);
        return true;
    }

    event ModifyBankKYCPermission(address indexed admin, address _bankAddress);

    /**
     * This function can only be used by the admin to change the status of kycPermission of any of the banks at any point of the time.
     * @param {address} _bankAddress address of the bank to be modified
     */
    function modifyBankKYCPermission(address _bankAddress)
        public
        isAdmin(msg.sender)
        isExistingBank(_bankAddress)
        returns (bool)
    {
        if (bankCount >= 5 && banks[_bankAddress].reports > bankCount / 3) {
            banks[_bankAddress].kycPermission = false;
        }
        emit ModifyBankKYCPermission(admin, _bankAddress);
        return banks[_bankAddress].kycPermission;
    }

    event RemoveBank(address indexed admin, address _bankAddress);

    /**
     * This function is used by the admin to remove a bank from the KYC Contract.
     * @param {address} _bankAddress address of the bank to be removed
     */
    function removeBank(address _bankAddress)
        public
        isAdmin(msg.sender)
        isExistingBank(_bankAddress)
        returns (bool)
    {
        delete banks[_bankAddress];
        bankCount--;
        emit RemoveBank(admin, _bankAddress);
        return true;
    }
}
