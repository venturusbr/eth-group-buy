# sharedeconomy

Esse repositório contém um projeto de smart contract para compra compartilhada em massa na blockchain, ideia pensada pelo Daniel Haro como caso de uso para o workshop do BC ["A tokenização das finanças: dos criptoativos às moedas digitais de bancos centrais"](https://www.bcb.gov.br/acessoinformacao/eventos/131). Usa o framework Hardhat.

Vendedores podem registrar lotes de itens tokenizados em forma de NFT e usuários fazem compras até que todo o lote seja vendido. Quando isso acontece, os usuários obtêm o token que representa o item físico e podem trocá-lo pessoalmente.

O ponto principal desse sistema é que um vendedor pode oferecer preço mais baixo em seus produtos caso seja garantido que vai vender um lote grande de uma vez só, como num atacado. Além disso existe toda a garantia de transparência e segurança da blockchain por trás, que registra a prova de pagamento, verifica que o vendedor possui propriedade sobre o que está anunciando, entre outros.

# Contratos

## SharedEconomy

É a implementação do sistema de compra compartilhada e permite que o dono de uma coleção NFT anuncie tokens para venda. Permite que usuários comprem itens e também permite o cancelamento até que o lote seja completamente vendido.

## BasicNft

É uma implementação básica de uma NFT seguindo o padrão [ERC721](https://ethereum.org/pt/developers/docs/standards/tokens/erc-721/), porém com uma função extra: 
```solidity
function mintMultiple(address receiver, uint256 amount) external
```

que é chamada pelo contrato Shared Economy para emitir NFTs para os compradores dos itens, após a venda completa de um lote.

## BasicNftFactory

É um criador de NFTs compatíveis com a Shared Economy. Usado para criar NFTs pelo usuário, sendo útil principalmente para exemplificar o funcionamento do sistema no frontend.

# Instalação

Precisa ter o npm ou yarn instalado.
```
git clone https://gitlab-vnt.venturus.org.br/venturus/chapters/blockchain/sharedeconomy.git
cd sharedeconomy
yarn install
```

# Testes

Foram criados testes unitários para verificar o funcionamento esperado dos contratos. Para executá-los:

```
yarn run hardhat test
```