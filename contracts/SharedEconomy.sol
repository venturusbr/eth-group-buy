// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface BatchIERC721 {
    function mintMultiple(address receiver, uint256 amount) external;
}

/// @title Contrato para compra compartilhada de itens tokenizados.
/// @notice Esse contrato permite que um usuário liste itens tokenizados
/// em forma de NFTs para venda em massa ("atacado").
/// Exemplo: 100 computadores tokenizados em 100 NFTs.
/// Se vendidos separadamente, cada unidade custará x, mas
/// quando comprados em massa, a unidade custará y sendo y < x.
/// @custom:experimental Esse contrato é uma ideia experimental.

contract SharedEconomy {
    error TokensAlreadyClaimed();
    error BatchOngoing(uint256 currentTime, uint256 timeLimit);
    error BatchExpired(uint256 currentTime, uint256 timeLimit);
    error BatchCompleted();
    error InsufficientValue(uint256 msgValue, uint256 itemsValue);
    error CancelAmountTooLarge(uint256 amount, uint256 itemsBought);
    error FailedToSendEther();

    struct Batch {
        address NFT;
        uint256 itemCount;
        uint256 itemPrice;
        uint256 buyCount;
        uint256 timeLimit;
        mapping(address => uint256) addressBuyCount;
        mapping(address => bool) claims;
    }

    uint256 batchIndex;
    Batch[] public batches;

    /// @notice Permite a criação de um lote para venda.
    /// @param _NFT o endereço do contrato NFT que representa o item do lote.
    /// @param _itemCount a quantidade de items a serem vendidos no lote.
    /// @param _timeLimit o tempo limite para a validade da venda do lote.
    function createBatch(
        address _NFT,
        uint256 _itemCount,
        uint256 _itemPrice,
        uint256 _timeLimit
    ) external {
        Batch storage b = batches[batchIndex];
        b.NFT = _NFT;
        b.itemCount = _itemCount;
        b.itemPrice = _itemPrice;
        b.timeLimit = _timeLimit;
        batchIndex++;
    }

    /// @notice Permite a compra de itens de um lote.
    /// @param batchIndex o índice do lote no array `batches`.
    /// @param amount a quantidade de itens a comprar.
    function buyItemFromBatch(
        uint256 batchIndex,
        uint256 amount
    ) external payable {
        Batch storage b = batches[batchIndex];
        if (b.buyCount + amount > b.itemCount) {
            revert BatchCompleted();
        }

        if (block.timestamp >= b.timeLimit) {
            revert BatchExpired(block.timestamp, b.timeLimit);
        }

        uint256 itemsValue = amount * b.itemPrice;
        if (msg.value != itemsValue) {
            revert InsufficientValue(msg.value, itemsValue);
        }

        b.addressBuyCount[msg.sender] += amount;
        b.buyCount += amount;
    }

    /// @notice Permite o cancelamento de compra de itens de um lote.
    /// @param batchIndex o índice do lote no array `batches`.
    /// @param amount a quantidade de itens a cancelar.
    function cancelPurchase(uint256 batchIndex, uint256 amount) external {
        Batch storage b = batches[batchIndex];

        if (block.timestamp >= b.timeLimit) {
            revert BatchExpired(block.timestamp, b.timeLimit);
        }
        uint256 addressBuyCount = b.addressBuyCount[msg.sender];
        if (amount > addressBuyCount) {
            revert CancelAmountTooLarge(amount, addressBuyCount);
        }

        b.buyCount -= amount;
        b.addressBuyCount[msg.sender] -= amount;
        (bool sent, bytes memory data) = msg.sender.call{
            value: addressBuyCount * b.itemPrice
        }("");
        if (!sent) {
            revert FailedToSendEther();
        }
    }

    /// @notice Permite que o usuário obtenha os itens tokenizados após o lote ser vendido.
    /// @param batchIndex o índice do lote no array `batches`
    function claimItems(uint256 batchIndex) external {
        Batch storage b = batches[batchIndex];

        if (block.timestamp < b.timeLimit) {
            revert BatchOngoing(block.timestamp, b.timeLimit);
        }

        if (b.claims[msg.sender]) {
            revert TokensAlreadyClaimed();
        }

        uint256 claimable = b.addressBuyCount[msg.sender];
        b.claims[msg.sender] = true;
        BatchIERC721(b.NFT).mintMultiple(msg.sender, claimable);
    }

    /// @notice Retorna informações sobre um lote.
    /// @param batchIndex o índice do lote no array `batches`
    function getBatchInfo(
        uint256 batchIndex
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        Batch storage b = batches[batchIndex];
        return (b.NFT, b.itemCount, b.itemPrice, b.buyCount, b.timeLimit);
    }

    /// @notice Retorna informações de um usuário sobre um lote.
    /// @param batchIndex o índice do lote no array `batches`
    /// @param user o endereço de um usuário
    function getUserBatchInfo(
        uint256 batchIndex,
        address user
    ) external view returns (uint256, bool) {
        Batch storage b = batches[batchIndex];
        return (b.addressBuyCount[user], b.claims[user]);
    }
}
