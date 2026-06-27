import Foundation

enum ResponseTestFixtures {
    static let nativeContracts = """
{
    "jsonrpc": "2.0",
    "id": 1,
    "result": [
        {
            "id": -6,
            "hash": "0xd2a4cff31913016155e38e474a2c06d08be276cf",
            "nef": {
                "magic": 860243278,
                "compiler": "neo-core-v3.0",
                "source": "variable-size-source-gastoken",
                "tokens": [],
                "script": "EEEa93tnQBBBGvd7Z0AQQRr3e2dAEEEa93tnQBBBGvd7Z0A=",
                "checksum": 2663858513
            },
            "manifest": {
                "name": "GasToken",
                "groups": [],
                "supportedstandards": [
                    "NEP-17"
                ],
                "abi": {
                    "methods": [
                        {
                            "name": "balanceOf",
                            "parameters": [
                                {
                                    "name": "account",
                                    "type": "Hash160"
                                }
                            ],
                            "returntype": "Integer",
                            "offset": 0,
                            "safe": true
                        },
                        {
                            "name": "decimals",
                            "parameters": [],
                            "returntype": "Integer",
                            "offset": 7,
                            "safe": true
                        },
                        {
                            "name": "symbol",
                            "parameters": [],
                            "returntype": "String",
                            "offset": 14,
                            "safe": true
                        },
                        {
                            "name": "totalSupply",
                            "parameters": [],
                            "returntype": "Integer",
                            "offset": 21,
                            "safe": true
                        },
                        {
                            "name": "transfer",
                            "parameters": [
                                {
                                    "name": "from",
                                    "type": "Hash160"
                                },
                                {
                                    "name": "to",
                                    "type": "Hash160"
                                },
                                {
                                    "name": "amount",
                                    "type": "Integer"
                                },
                                {
                                    "name": "data",
                                    "type": "Any"
                                }
                            ],
                            "returntype": "Boolean",
                            "offset": 28,
                            "safe": false
                        }
                    ],
                    "events": [
                        {
                            "name": "Transfer",
                            "parameters": [
                                {
                                    "name": "from",
                                    "type": "Hash160"
                                },
                                {
                                    "name": "to",
                                    "type": "Hash160"
                                },
                                {
                                    "name": "amount",
                                    "type": "Integer"
                                }
                            ]
                        }
                    ]
                },
                "permissions": [
                    {
                        "contract": "*",
                        "methods": "*"
                    }
                ],
                "trusts": [],
                "extra": null
            },
            "updatehistory": [
                0
            ]
        },
        {
            "id": -8,
            "hash": "0x49cf4e5378ffcd4dec034fd98a174c5491e395e2",
            "nef": {
                "magic": 860243278,
                "compiler": "neo-core-v3.0",
                "source": "variable-size-source-rolemanagement",
                "tokens": [],
                "script": "EEEa93tnQBBBGvd7Z0A=",
                "checksum": 983638438
            },
            "manifest": {
                "name": "RoleManagement",
                "groups": [],
                "supportedstandards": [],
                "abi": {
                    "methods": [
                        {
                            "name": "designateAsRole",
                            "parameters": [
                                {
                                    "name": "role",
                                    "type": "Integer"
                                },
                                {
                                    "name": "nodes",
                                    "type": "Array"
                                }
                            ],
                            "returntype": "Void",
                            "offset": 0,
                            "safe": false
                        },
                        {
                            "name": "getDesignatedByRole",
                            "parameters": [
                                {
                                    "name": "role",
                                    "type": "Integer"
                                },
                                {
                                    "name": "index",
                                    "type": "Integer"
                                }
                            ],
                            "returntype": "Array",
                            "offset": 7,
                            "safe": true
                        }
                    ],
                    "events": []
                },
                "permissions": [
                    {
                        "contract": "*",
                        "methods": "*"
                    }
                ],
                "trusts": [],
                "extra": null
            },
            "updatehistory": [
                0
            ]
        },
        {
            "id": -9,
            "hash": "0xfe924b7cfe89ddd271abaf7210a80a7e11178758",
            "nef": {
                "magic": 860243278,
                "compiler": "neo-core-v3.0",
                "source": "variable-size-source-oraclecontract",
                "tokens": [],
                "script": "EEEa93tnQBBBGvd7Z0AQQRr3e2dAEEEa93tnQBBBGvd7Z0A=",
                "checksum": 2663858513
            },
            "manifest": {
                "name": "OracleContract",
                "groups": [],
                "supportedstandards": [],
                "abi": {
                    "methods": [
                        {
                            "name": "finish",
                            "parameters": [],
                            "returntype": "Void",
                            "offset": 0,
                            "safe": false
                        },
                        {
                            "name": "getPrice",
                            "parameters": [],
                            "returntype": "Integer",
                            "offset": 7,
                            "safe": true
                        },
                        {
                            "name": "request",
                            "parameters": [
                                {
                                    "name": "url",
                                    "type": "String"
                                },
                                {
                                    "name": "filter",
                                    "type": "String"
                                },
                                {
                                    "name": "callback",
                                    "type": "String"
                                },
                                {
                                    "name": "userData",
                                    "type": "Any"
                                },
                                {
                                    "name": "gasForResponse",
                                    "type": "Integer"
                                }
                            ],
                            "returntype": "Void",
                            "offset": 14,
                            "safe": false
                        },
                        {
                            "name": "setPrice",
                            "parameters": [
                                {
                                    "name": "price",
                                    "type": "Integer"
                                }
                            ],
                            "returntype": "Void",
                            "offset": 21,
                            "safe": false
                        },
                        {
                            "name": "verify",
                            "parameters": [],
                            "returntype": "Boolean",
                            "offset": 28,
                            "safe": true
                        }
                    ],
                    "events": [
                        {
                            "name": "OracleRequest",
                            "parameters": [
                                {
                                    "name": "Id",
                                    "type": "Integer"
                                },
                                {
                                    "name": "RequestContract",
                                    "type": "Hash160"
                                },
                                {
                                    "name": "Url",
                                    "type": "String"
                                },
                                {
                                    "name": "Filter",
                                    "type": "String"
                                }
                            ]
                        },
                        {
                            "name": "OracleResponse",
                            "parameters": [
                                {
                                    "name": "Id",
                                    "type": "Integer"
                                },
                                {
                                    "name": "OriginalTx",
                                    "type": "Hash256"
                                }
                            ]
                        }
                    ]
                },
                "permissions": [
                    {
                        "contract": "*",
                        "methods": "*"
                    }
                ],
                "trusts": [],
                "extra": null
            },
            "updatehistory": [
                0
            ]
        }
    ]
}
"""
}
