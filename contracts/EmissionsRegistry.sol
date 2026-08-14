// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

///@title EmissionsRegistry
///@notice Blockchain-based Monitoring, Reporting and Verification (MRV) registry
///         for greenhouse gas emissions data. Stores tamper-evident hashes of
///         off-chain emissions reports, submitted by authorised facilities and
///         verifiable by regulators and independent auditors.
contract EmissionsRegistry {
    // *************STATE***********

    /// @notice The regulator's address, set once at deployment, acts as admin.
    address public regulator;

    struct Facility {
        string name;
        address facilityAddress;
        bool isRegistered;
    }

    struct EmissionsRecord {
        bytes32 dataHash;   // hash of the full off-chain emissions report
        uint256 timestamp;
        address submittedBy;
    }

    /// @dev Maps a facility's wallet address to its registration details.
    mapping(address => Facility) public facilities;

    /// @dev Maps a facility's wallet address to the full history of its submitted records.
    mapping(address => EmissionsRecord[]) private facilityRecords;
    
    // ******************EVENTS**********************

    event Facility_Registered(address indexed facilityAddress, string name);
    event EmissionsRecords_Submitted(address indexed facility, bytes32 dataHash, uint256 timestamp);

    // *****************MODIFIERS*********************

    modifier RegulatorOnly() {
        require(msg.sender == regulator, "Regulator only, you're not authorised");
        _;
    }

    modifier RegisteredFacilityOnly() {
        require(facilities[msg.sender].isRegistered, "Facility not registered");
        _;
    }

    // *********************CONSTRUCTOR*******************

    /// @notice The deployer's wallet becomes the regulator (admin) automatically.
    constructor() {
        regulator = msg.sender;
    }

    // ********************FACILITY REGISTRATION*******************

    // @notice Registers a new manufacturing facility. Only the regulator may call this.
    /// @param facilityAddr The wallet address representing the facility.
    /// @param name A readable name for the facility.
    function registerFacility(address facilityAddr, string calldata name) external RegulatorOnly {
        require(facilityAddr != address(0), "Invalid facility address");
        require(!facilities[facilityAddr].isRegistered, "Facility already registred");
        require(bytes(name).length >0, "Facility name not entered");

        facilities[facilityAddr] = Facility({
            name: name,
            facilityAddress: facilityAddr,
            isRegistered: true
        });

        emit Facility_Registered(facilityAddr,name);
    }

    // ****************************EMISSSIONS RECORD SUBMISSION*******************************

    // @notice Submits the hash of an emissions report for the calling facility.
    /// @param dataHash The keccak256/SHA-256 hash of the full off-chain emissions report.
    function submitEmissionsRecord(bytes32 dataHash) external RegisteredFacilityOnly {
        require(dataHash != bytes32(0), "Data hash not provided");
        
        facilityRecords[msg.sender].push(EmissionsRecord ({
            dataHash: dataHash,
            timestamp: block.timestamp,
            submittedBy: msg.sender
        }));

        emit EmissionsRecords_Submitted(msg.sender, dataHash, block.timestamp);
    } 

    // *********************************RECORDS RETRIEVAL**************************************

    /// @notice Retrieves all submitted emissions records for a given facility.
    /// @dev Public view function, anyone can call this to verify records.
    /// @param facilityAddr The facility whose records are being requested.
    function getRecords(address facilityAddr) external view returns (EmissionsRecord[] memory){
        return facilityRecords[facilityAddr];
    } 

    /// @notice Returns the number of records submitted by a given facility.
    function getRecordCount(address facilityAddr) external view returns (uint256){
        return facilityRecords[facilityAddr].length;
    }





}