// SPDX-License-Identifier: MIT
//  _____     _ _         _         _
// |_   _|_ _(_) |_____  | |   __ _| |__ ___
//   | |/ _` | | / / _ \ | |__/ _` | '_ (_-<
//   |_|\__,_|_|_\_\___/ |____\__,_|_.__/__/

pragma solidity ^0.8.20;

/// @title TaikoData
/// @notice This library defines various data structures used in the Taiko
/// protocol.
library TaikoData {
    /// @dev Struct holding Taiko configuration parameters. See {TaikoConfig}.
    struct Config {
        // ---------------------------------------------------------------------
        // Group 1: General configs
        // ---------------------------------------------------------------------
        // The chain ID of the network where Taiko contracts are deployed.
        uint256 chainId;
        // Flag indicating whether the relay signal root is enabled or not.
        bool relaySignalRoot;
        // ---------------------------------------------------------------------
        // Group 2: Block level configs
        // ---------------------------------------------------------------------
        // The maximum number of proposals allowed in a single block.
        uint64 blockMaxProposals;
        // Size of the block ring buffer, allowing extra space for proposals.
        uint64 blockRingBufferSize;
        // The maximum number of verifications allowed per transaction in a
        // block.
        uint64 blockMaxVerificationsPerTx;
        // The maximum gas limit allowed for a block.
        uint32 blockMaxGasLimit;
        // The base gas for processing a block.
        uint32 blockFeeBaseGas;
        // The maximum number of transactions allowed in a single block.
        uint64 blockMaxTransactions;
        // The maximum allowed bytes for the proposed transaction list calldata.
        uint64 blockMaxTxListBytes;
        // The expiration time for the block transaction list.
        uint256 blockTxListExpiry;
        // ---------------------------------------------------------------------
        // Group 3: Proof related configs
        // ---------------------------------------------------------------------
        // The cooldown period for regular proofs (in minutes).
        uint256 proofRegularCooldown;
        // The cooldown period for oracle proofs (in minutes).
        uint256 proofOracleCooldown;
        // The maximum time window allowed for a proof submission (in minutes).
        uint16 proofWindow;
        // The amount of Taiko token as a bond
        uint256 proofBond;
        // ---------------------------------------------------------------------
        // Group 4: ETH deposit related configs
        // ---------------------------------------------------------------------
        // The size of the ETH deposit ring buffer.
        uint256 ethDepositRingBufferSize;
        // The minimum number of ETH deposits allowed per block.
        uint64 ethDepositMinCountPerBlock;
        // The maximum number of ETH deposits allowed per block.
        uint64 ethDepositMaxCountPerBlock;
        // The minimum amount of ETH required for a deposit.
        uint96 ethDepositMinAmount;
        // The maximum amount of ETH allowed for a deposit.
        uint96 ethDepositMaxAmount;
        // The gas cost for processing an ETH deposit.
        uint256 ethDepositGas;
        // The maximum fee allowed for an ETH deposit.
        uint256 ethDepositMaxFee;
    }

    /// @dev Struct holding state variables.
    struct StateVariables {
        uint64 genesisHeight;
        uint64 genesisTimestamp;
        uint64 numBlocks;
        uint64 lastVerifiedBlockId;
        uint64 nextEthDepositToProcess;
        uint64 numEthDeposits;
    }

    /// @dev Struct representing input data for block metadata.
    /// 2 slots.
    struct BlockMetadataInput {
        bytes32 txListHash;
        address beneficiary;
        uint24 txListByteStart; // byte-wise start index (inclusive)
        uint24 txListByteEnd; // byte-wise end index (exclusive)
        bool cacheTxListInfo;
        address prover;
        uint64 maxProverFee;
        bytes proverParams;
    }

    /// @dev Struct containing data only required for proving a block
    /// Warning: changing this struct requires changing {LibUtils.hashMetadata}
    /// accordingly.
    struct BlockMetadata {
        uint64 id;
        uint64 timestamp;
        uint64 l1Height;
        bytes32 l1Hash;
        bytes32 mixHash;
        bytes32 txListHash;
        uint24 txListByteStart;
        uint24 txListByteEnd;
        uint32 gasLimit;
        address beneficiary;
        TaikoData.EthDeposit[] depositsProcessed;
    }

    /// @dev Struct representing block evidence.
    struct BlockEvidence {
        bytes32 metaHash;
        bytes32 parentHash;
        bytes32 blockHash;
        bytes32 signalRoot;
        bytes32 graffiti;
        address prover;
        uint32 parentGasUsed;
        uint32 gasUsed;
        bytes proofs;
    }

    /// @dev Struct representing fork choice data.
    /// 4 slots.
    struct ForkChoice {
        // key is only written/read for the 1st fork choice.
        bytes32 key;
        bytes32 blockHash;
        bytes32 signalRoot;
        address prover;
        uint64 provenAt;
        uint32 gasUsed;
    }

    /// @dev Struct containing data required for verifying a block.
    /// 3 slots.
    struct Block {
        // slot 1: ForkChoice storage are reusable
        mapping(uint16 forkChoiceId => ForkChoice) forkChoices;
        bytes32 metaHash; // slot 2
        address prover; // slot 3
        uint64 proposedAt;
        uint16 nextForkChoiceId;
        uint16 verifiedForkChoiceId;
    }

    /// @dev Struct representing information about a transaction list.
    struct TxListInfo {
        uint64 validSince;
        uint24 size;
    }

    /// @dev Struct representing an Ethereum deposit.
    struct EthDeposit {
        address recipient;
        uint96 amount;
        uint64 id;
    }

    /// @dev Forge is only able to run coverage in case the contracts by default
    /// capable of compiling without any optimization (neither optimizer runs,
    /// no compiling --via-ir flag).
    /// In order to resolve stack too deep without optimizations, we needed to
    /// introduce outsourcing vars into structs below.
    struct SlotA {
        uint64 genesisHeight;
        uint64 genesisTimestamp;
        uint64 numEthDeposits;
        uint64 nextEthDepositToProcess;
    }

    struct SlotB {
        uint64 numBlocks;
        uint64 nextEthDepositToProcess;
        uint64 lastVerifiedAt;
        uint64 lastVerifiedBlockId;
    }

    /// @dev Struct holding the state variables for the {TaikoL1} contract.
    struct State {
        // Ring buffer for proposed blocks and a some recent verified blocks.
        mapping(uint64 blockId_mode_blockRingBufferSize => Block) blocks;
        mapping(
            uint64 blockId
                => mapping(
                    bytes32 parentHash
                        => mapping(uint32 parentGasUsed => uint16 forkChoiceId)
                )
            ) forkChoiceIds;
        mapping(bytes32 txListHash => TxListInfo) txListInfo;
        mapping(uint256 depositId_mode_ethDepositRingBufferSize => uint256)
            ethDeposits;
        SlotA slotA; // slot 5
        SlotB slotB; // slot 6
        uint256[44] __gap;
    }
}
