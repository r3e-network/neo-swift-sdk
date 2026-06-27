import BigInt
import XCTest
@testable import NeoSwiftSDK

extension ResponseTests {
    
    public func testGetBlock() {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "0x1de7e5eaab0f74ac38f5191c038e009d3c93ef5c392d1d66fa95ab164ba308b8",
        "size": 1217,
        "version": 0,
        "previousblockhash": "0x045cabde4ecbd50f5e4e1b141eaf0842c1f5f56517324c8dcab8ccac924e3a39",
        "merkleroot": "0x6afa63201b88b55ad2213e5a69a1ad5f0db650bc178fc2bedd2fb301c1278bf7",
        "time": 1539968858,
        "index": 1914006,
        "nextconsensus": "AWZo4qAxhT8fwKL93QATSjCYCgHmCY1XLB",
        "witnesses": [
            {
                "invocation": "DEBJVWapboNkCDlH9uu+tStOgGnwODlolRifxTvQiBkhM0vplSPo4vMj9Jt3jvzztMlwmO75Ss5cptL8wUMxASjZ",
                "verification": "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
            }
        ],
        "tx": [
            {
                "hash": "0x46eca609a9a8c8340ee56b174b04bc9c9f37c89771c3a8998dc043f5a74ad510",
                "size": 267,
                "version": 0,
                "nonce": 565086327,
                "sender": "AHE5cLhX5NjGB5R2PcdUvGudUoGUBDeHX4",
                "sysfee": "0",
                "netfee": "0",
                "validuntilblock": 2107425,
                "signers": [
                    {
                        "account": "0xf68f181731a47036a99f04dad90043a744edec0f",
                        "scopes": "CalledByEntry"
                    }
                ],
                "attributes": [],
                "script": "AGQMFObBATZUrxE9ipaL3KUsmUioK5U9DBQP7O1Ep0MA2doEn6k2cKQxFxiP9hPADAh0cmFuc2ZlcgwUiXcg2M129PAKv6N8Dt2InCCP3ptBYn1bUjg",
                "witnesses": [
                    {
                        "invocation": "DEBR7EQOb1NUjat1wrINzBNKOQtXoUmRVZU8h5c8K5CLMCUVcGkFVqAAGUJDh3mVcz6sTgXvmMuujWYrBveeM4q+",
                        "verification": "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
                    }
                ]
            },
            {
                "hash": "0x46eca609a9a8c8340ee56b174b04bc9c9f37c89771c3a8998dc043f5a74ad510",
                "size": 267,
                "version": 0,
                "nonce": 565086327,
                "sender": "AHE5cLhX5NjGB5R2PcdUvGudUoGUBDeHX4",
                "sysfee": "0",
                "netfee": "0",
                "validuntilblock": 2107425,
                "signers": [
                    {
                        "account": "0xf68f181731a47036a99f04dad90043a744edec0f",
                        "scopes": "CalledByEntry"
                    }
                ],
                "attributes": [],
                "script": "AGQMFObBATZUrxE9ipaL3KUsmUioK5U9DBQP7O1Ep0MA2doEn6k2cKQxFxiP9hPADAh0cmFuc2ZlcgwUiXcg2M129PAKv6N8Dt2InCCP3ptBYn1bUjg",
                "witnesses": [
                    {
                        "invocation": "DEBR7EQOb1NUjat1wrINzBNKOQtXoUmRVZU8h5c8K5CLMCUVcGkFVqAAGUJDh3mVcz6sTgXvmMuujWYrBveeM4q+",
                        "verification": "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
                    }
                ]
            }
        ],
        "confirmations": 7878,
        "nextblockhash": "0x4a97ca89199627f877b6bffe865b8327be84b368d62572ef20953829c3501643"
    }
}
"""
        let getBlock = decodeJson(NeoGetBlock.self, from: json)
        XCTAssertEqual(getBlock.block?.hash, try! Hash256("0x1de7e5eaab0f74ac38f5191c038e009d3c93ef5c392d1d66fa95ab164ba308b8"))
        XCTAssertEqual(getBlock.block?.size, 1217)
        XCTAssertEqual(getBlock.block?.version, 0)
        XCTAssertEqual(getBlock.block?.prevBlockHash, try! Hash256("0x045cabde4ecbd50f5e4e1b141eaf0842c1f5f56517324c8dcab8ccac924e3a39"))
        XCTAssertEqual(getBlock.block?.merkleRootHash, try! Hash256("0x6afa63201b88b55ad2213e5a69a1ad5f0db650bc178fc2bedd2fb301c1278bf7"))
        XCTAssertEqual(getBlock.block?.time, 1539968858)
        XCTAssertEqual(getBlock.block?.index, 1914006)
        XCTAssertEqual(getBlock.block?.nextConsensus, "AWZo4qAxhT8fwKL93QATSjCYCgHmCY1XLB")
        XCTAssertEqual(getBlock.block?.version, 0)
        
        XCTAssertEqual(getBlock.block?.witnesses?.count, 1)
        XCTAssert(getBlock.block?.witnesses?.contains(NeoWitness(
            "DEBJVWapboNkCDlH9uu+tStOgGnwODlolRifxTvQiBkhM0vplSPo4vMj9Jt3jvzztMlwmO75Ss5cptL8wUMxASjZ",
            "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
        )) ?? false)
        
        XCTAssertEqual(getBlock.block?.transactions?.count, 2)
        let transactions = [
            Transaction(
                hash: try! Hash256("0x46eca609a9a8c8340ee56b174b04bc9c9f37c89771c3a8998dc043f5a74ad510"),
                size: 267,
                version: 0,
                nonce: 565086327,
                sender: "AHE5cLhX5NjGB5R2PcdUvGudUoGUBDeHX4",
                sysFee: "0",
                netFee: "0",
                validUntilBlock: 2107425,
                signers: [TransactionSigner(try!  Hash160("0xf68f181731a47036a99f04dad90043a744edec0f"), [.calledByEntry])],
                attributes: [],
                script: "AGQMFObBATZUrxE9ipaL3KUsmUioK5U9DBQP7O1Ep0MA2doEn6k2cKQxFxiP9hPADAh0cmFuc2ZlcgwUiXcg2M129PAKv6N8Dt2InCCP3ptBYn1bUjg",
                witnesses: [NeoWitness(
                    "DEBR7EQOb1NUjat1wrINzBNKOQtXoUmRVZU8h5c8K5CLMCUVcGkFVqAAGUJDh3mVcz6sTgXvmMuujWYrBveeM4q+",
                    "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
                )]
            ),
            Transaction(
                hash: try! Hash256("0x46eca609a9a8c8340ee56b174b04bc9c9f37c89771c3a8998dc043f5a74ad510"),
                size: 267,
                version: 0,
                nonce: 565086327,
                sender: "AHE5cLhX5NjGB5R2PcdUvGudUoGUBDeHX4",
                sysFee: "0",
                netFee: "0",
                validUntilBlock: 2107425,
                signers: [TransactionSigner(try! Hash160("0xf68f181731a47036a99f04dad90043a744edec0f"), [.calledByEntry])],
                attributes: [],
                script: "AGQMFObBATZUrxE9ipaL3KUsmUioK5U9DBQP7O1Ep0MA2doEn6k2cKQxFxiP9hPADAh0cmFuc2ZlcgwUiXcg2M129PAKv6N8Dt2InCCP3ptBYn1bUjg",
                witnesses: [NeoWitness(
                    "DEBR7EQOb1NUjat1wrINzBNKOQtXoUmRVZU8h5c8K5CLMCUVcGkFVqAAGUJDh3mVcz6sTgXvmMuujWYrBveeM4q+",
                    "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
                )]
            )
        ]
        transactions.forEach {
            XCTAssert(getBlock.block?.transactions?.contains($0) ?? false)
        }
        
        XCTAssertEqual(getBlock.block?.confirmations, 7878)
        XCTAssertEqual(getBlock.block?.nextBlockHash, try! Hash256("0x4a97ca89199627f877b6bffe865b8327be84b368d62572ef20953829c3501643"))
    }
    
    public func testGetBlockBlockHeader() {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
        "hash": "0x1de7e5eaab0f74ac38f5191c038e009d3c93ef5c392d1d66fa95ab164ba308b8",
        "size": 1217,
        "version": 0,
        "previousblockhash": "0x045cabde4ecbd50f5e4e1b141eaf0842c1f5f56517324c8dcab8ccac924e3a39",
        "merkleroot": "0x6afa63201b88b55ad2213e5a69a1ad5f0db650bc178fc2bedd2fb301c1278bf7",
        "time": 1539968858,
        "index": 1914006,
        "nextconsensus": "AWZo4qAxhT8fwKL93QATSjCYCgHmCY1XLB",
        "witnesses": [
            {
                "invocation": "DEBJVWapboNkCDlH9uu+tStOgGnwODlolRifxTvQiBkhM0vplSPo4vMj9Jt3jvzztMlwmO75Ss5cptL8wUMxASjZ",
                "verification": "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
            }
        ],
        "confirmations": 7878,
        "nextblockhash": "0x4a97ca89199627f877b6bffe865b8327be84b368d62572ef20953829c3501643"
    }
}
"""
        let getBlock = decodeJson(NeoGetBlock.self, from: json)
        XCTAssertEqual(getBlock.block?.hash, try! Hash256("0x1de7e5eaab0f74ac38f5191c038e009d3c93ef5c392d1d66fa95ab164ba308b8"))
        XCTAssertEqual(getBlock.block?.size, 1217)
        XCTAssertEqual(getBlock.block?.version, 0)
        XCTAssertEqual(getBlock.block?.prevBlockHash, try! Hash256("0x045cabde4ecbd50f5e4e1b141eaf0842c1f5f56517324c8dcab8ccac924e3a39"))
        XCTAssertEqual(getBlock.block?.merkleRootHash, try! Hash256("0x6afa63201b88b55ad2213e5a69a1ad5f0db650bc178fc2bedd2fb301c1278bf7"))
        XCTAssertEqual(getBlock.block?.time, 1539968858)
        XCTAssertEqual(getBlock.block?.index, 1914006)
        XCTAssertEqual(getBlock.block?.nextConsensus, "AWZo4qAxhT8fwKL93QATSjCYCgHmCY1XLB")
        
        XCTAssertEqual(getBlock.block?.witnesses?.count, 1)
        XCTAssert(getBlock.block?.witnesses?.contains(NeoWitness(
            "DEBJVWapboNkCDlH9uu+tStOgGnwODlolRifxTvQiBkhM0vplSPo4vMj9Jt3jvzztMlwmO75Ss5cptL8wUMxASjZ",
            "EQwhA/HsPB4oPogN5unEifDyfBkAfFM4WqpMDJF8MgB57a3yEQtBMHOzuw=="
        )) ?? false)
        
        XCTAssertNil(getBlock.block?.transactions)
        
        XCTAssertEqual(getBlock.block?.confirmations, 7878)
        XCTAssertEqual(getBlock.block?.nextBlockHash, try! Hash256("0x4a97ca89199627f877b6bffe865b8327be84b368d62572ef20953829c3501643"))
    }
    
    public func testGetRawBlock() {
        let json = """
{
    "jsonrpc": "2.0",
    "id": 67,
    "result": "00000000ebaa4ed893333db1ed556bb24145f4e7fe40b9c7c07ff2235c7d3d361ddb27e603da9da4c7420d090d0e29c588cfd701b3f81819375e537c634bd779ddc7e2e2c436cc5ba53f00001952d428256ad0cdbe48d3a3f5d10013ab9ffee489706078714f1ea201c340c44387d762d1bcb2ab0ec650628c7c674021f333ee7666e2a03805ad86df3b826b5dbf5ac607a361807a047d43cf6bba726dcb06a42662aee7e78886c72faef940e6cef9abab82e1e90c6683ac8241b3bf51a10c908f01465f19c3df1099ef5de5d43a648a6e4ab63cc7d5e88146bddbe950e8041e44a2b0b81f21ad706e88258540fd19314f46ad452b4cbedf58bf9d266c0c808374cd33ef18d9a0575b01e47f6bb04abe76036619787c457c49288aeb91ff23cdb85771c0209db184801d5bdd348b532102103a7f7dd016558597f7960d27c516a4394fd968b9e65155eb4b013e4040406e2102a7bc55fe8684e0119768d104ba30795bdcc86619e864add26156723ed185cd622102b3622bf4017bdfe317c58aed5f4c753f206b7db896046fa7d774bbc4bf7f8dc22103d90c07df63e690ce77912e10ab51acc944b66860237b608c4f8f8309e71ee69954ae0100001952d42800000000"
}
"""
        let rawBlock = decodeJson(NeoGetRawBlock.self, from: json)
        XCTAssertEqual(rawBlock.rawBlock,
                       "00000000ebaa4ed893333db1ed556bb24145f4e7fe40b9c7c07ff2235c7d3d361ddb27e603da9da4c7420d090d0e29c588cfd701b3f81819375e537c634bd779ddc7e2e2c436cc5ba53f00001952d428256ad0cdbe48d3a3f5d10013ab9ffee489706078714f1ea201c340c44387d762d1bcb2ab0ec650628c7c674021f333ee7666e2a03805ad86df3b826b5dbf5ac607a361807a047d43cf6bba726dcb06a42662aee7e78886c72faef940e6cef9abab82e1e90c6683ac8241b3bf51a10c908f01465f19c3df1099ef5de5d43a648a6e4ab63cc7d5e88146bddbe950e8041e44a2b0b81f21ad706e88258540fd19314f46ad452b4cbedf58bf9d266c0c808374cd33ef18d9a0575b01e47f6bb04abe76036619787c457c49288aeb91ff23cdb85771c0209db184801d5bdd348b532102103a7f7dd016558597f7960d27c516a4394fd968b9e65155eb4b013e4040406e2102a7bc55fe8684e0119768d104ba30795bdcc86619e864add26156723ed185cd622102b3622bf4017bdfe317c58aed5f4c753f206b7db896046fa7d774bbc4bf7f8dc22103d90c07df63e690ce77912e10ab51acc944b66860237b608c4f8f8309e71ee69954ae0100001952d42800000000")
    }
}
