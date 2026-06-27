# NeoCSharp Complete Architecture Design

## Executive Summary

This document presents the complete architecture design for NeoCSharp, a comprehensive C# SDK for Neo blockchain development. The design is based on the mature Swift SDK structure while incorporating modern .NET patterns, dependency injection, async/await patterns, and enterprise-grade security considerations.

## 1. .NET Solution Structure

### 1.1 Project Organization

```
NeoCSharp/
├── NeoCSharp.sln                           # Main solution file
├── src/                                    # Source code
│   ├── NeoCSharp/                         # Core library
│   │   ├── NeoCSharp.csproj              # Main project file
│   │   └── [source files]
│   ├── NeoCSharp.Extensions/              # Optional extensions
│   └── NeoCSharp.AspNetCore/              # ASP.NET Core integration
├── tests/                                  # Test projects
│   ├── NeoCSharp.Tests/                   # Unit tests
│   ├── NeoCSharp.Integration.Tests/       # Integration tests
│   └── NeoCSharp.Performance.Tests/       # Performance tests
├── examples/                              # Example applications
│   ├── NeoCSharp.Examples.Console/
│   ├── NeoCSharp.Examples.Web/
│   └── NeoCSharp.Examples.Wpf/
├── docs/                                  # Documentation
├── build/                                 # Build scripts and configuration
├── tools/                                 # Development tools
└── nuget/                                 # NuGet packaging configuration
```

### 1.2 Target Framework Strategy

**Primary Target**: .NET 8.0 (LTS)
**Secondary Targets**: .NET Standard 2.1 (for broader compatibility)

```xml
<TargetFrameworks>net8.0;netstandard2.1</TargetFrameworks>
<LangVersion>latest</LangVersion>
<Nullable>enable</Nullable>
```

## 2. C# Namespace Hierarchy

### 2.1 Core Namespace Structure

```csharp
NeoCSharp                                   // Root namespace
├── NeoCSharp.Core                         // Core types and constants
├── NeoCSharp.Crypto                       // Cryptographic operations
│   ├── NeoCSharp.Crypto.Keys              // Key management
│   ├── NeoCSharp.Crypto.Signing           // Digital signatures
│   └── NeoCSharp.Crypto.Helpers           // Cryptographic utilities
├── NeoCSharp.Protocol                     // RPC client and network communication
│   ├── NeoCSharp.Protocol.Core            // Core protocol types
│   │   ├── NeoCSharp.Protocol.Core.Response   // RPC response models
│   │   └── NeoCSharp.Protocol.Core.Request    // RPC request models
│   ├── NeoCSharp.Protocol.Http            // HTTP transport layer
│   └── NeoCSharp.Protocol.WebSocket       // WebSocket support (future)
├── NeoCSharp.Contracts                    // Smart contract interaction
│   ├── NeoCSharp.Contracts.Standards      // NEP standards (NEP-17, NEP-11)
│   └── NeoCSharp.Contracts.Native         // Native contracts
├── NeoCSharp.Transactions                 // Transaction building and signing
├── NeoCSharp.Scripts                      // Script building and execution
├── NeoCSharp.Serialization               // Binary serialization
├── NeoCSharp.Wallets                     // Wallet management
│   └── NeoCSharp.Wallets.NEP6            // NEP-6 wallet format
├── NeoCSharp.Types                       // Common types (Hash160, Hash256, etc.)
├── NeoCSharp.Utils                       // Utility functions
└── NeoCSharp.Extensions                  // Extension methods
```

### 2.2 Namespace Design Principles

1. **Logical Grouping**: Related functionality grouped by domain
2. **Hierarchical Organization**: Clear parent-child relationships  
3. **Avoid Deep Nesting**: Maximum 3-4 levels deep
4. **Consistent Naming**: PascalCase with descriptive names
5. **Future-Proof**: Allow for easy extension without breaking changes

## 3. Dependency Injection Patterns

### 3.1 Service Registration Architecture

```csharp
// Core services registration
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddNeoCSharp(this IServiceCollection services, 
        Action<NeoCSharpOptions> configure = null)
    {
        var options = new NeoCSharpOptions();
        configure?.Invoke(options);
        
        // Core services
        services.AddSingleton(options);
        services.AddSingleton<IHashService, HashService>();
        services.AddSingleton<ISignatureService, SignatureService>();
        services.AddTransient<IKeyPairGenerator, ECKeyPairGenerator>();
        
        // HTTP client configuration
        services.AddHttpClient<INeoClient, NeoClient>(client =>
        {
            client.BaseAddress = new Uri(options.NodeUrl);
            client.Timeout = TimeSpan.FromSeconds(options.TimeoutSeconds);
        });
        
        // Protocol services
        services.AddTransient<ITransactionBuilder, TransactionBuilder>();
        services.AddTransient<IScriptBuilder, ScriptBuilder>();
        services.AddTransient<IContractInvoker, ContractInvoker>();
        
        // Wallet services
        services.AddTransient<IWalletService, WalletService>();
        services.AddTransient<IAccountService, AccountService>();
        
        return services;
    }
}
```

### 3.2 Configuration Options Pattern

```csharp
public class NeoCSharpOptions
{
    public string NodeUrl { get; set; } = "http://localhost:20332";
    public int TimeoutSeconds { get; set; } = 30;
    public string NetworkMagic { get; set; } = "860833102"; // MainNet
    public int AddressVersion { get; set; } = 53;
    public Hash160 NnsResolver { get; set; }
    public int BlockInterval { get; set; } = 15000;
    public int PollingInterval { get; set; } = 1000;
    public int MaxValidUntilBlockIncrement { get; set; } = 5760;
    public bool EnableDiagnostics { get; set; } = false;
    public bool EnableTransmissionOnFault { get; set; } = false;
    
    // Security settings
    public SecurityOptions Security { get; set; } = new SecurityOptions();
}

public class SecurityOptions
{
    public bool ValidateCertificates { get; set; } = true;
    public TimeSpan KeyCacheTimeout { get; set; } = TimeSpan.FromMinutes(5);
    public bool EnableSecureMemory { get; set; } = true;
    public int MaxRetryAttempts { get; set; } = 3;
}
```

### 3.3 Interface Design Strategy

```csharp
// Primary client interface
public interface INeoClient : IDisposable
{
    // Blockchain operations
    Task<Hash256> GetBestBlockHashAsync(CancellationToken cancellationToken = default);
    Task<NeoBlock> GetBlockAsync(Hash256 blockHash, CancellationToken cancellationToken = default);
    
    // Smart contract operations
    Task<InvocationResult> InvokeFunctionAsync<T>(Hash160 contractHash, string method, 
        T[] parameters, CancellationToken cancellationToken = default) where T : ContractParameter;
    
    // Transaction operations
    Task<TransactionResult> SendTransactionAsync(Transaction transaction, 
        CancellationToken cancellationToken = default);
}

// Service interfaces for dependency injection
public interface ITransactionBuilder
{
    TransactionBuilder AddWitness(Witness witness);
    TransactionBuilder SetSystemFee(long fee);
    TransactionBuilder SetNetworkFee(long fee);
    Transaction Build();
}

public interface IWalletService
{
    Task<Wallet> CreateWalletAsync(string password, string filePath = null);
    Task<Wallet> LoadWalletAsync(string filePath, string password);
    Task<Account> CreateAccountAsync(Wallet wallet);
    Task<bool> SaveWalletAsync(Wallet wallet, string filePath);
}
```

## 4. Async/Await Patterns for HTTP Operations

### 4.1 HTTP Client Architecture

```csharp
public class HttpService : IHttpService, IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<HttpService> _logger;
    private readonly NeoCSharpOptions _options;
    private readonly SemaphoreSlim _rateLimiter;

    public HttpService(HttpClient httpClient, ILogger<HttpService> logger, 
        IOptions<NeoCSharpOptions> options)
    {
        _httpClient = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
        _logger = logger;
        _options = options.Value;
        _rateLimiter = new SemaphoreSlim(_options.MaxConcurrentRequests, _options.MaxConcurrentRequests);
    }

    public async Task<TResponse> SendAsync<TResponse>(string method, object[] parameters = null, 
        CancellationToken cancellationToken = default)
    {
        await _rateLimiter.WaitAsync(cancellationToken);
        
        try
        {
            var request = CreateJsonRpcRequest(method, parameters);
            var content = new StringContent(JsonSerializer.Serialize(request), 
                Encoding.UTF8, "application/json");

            using var response = await _httpClient.PostAsync("", content, cancellationToken);
            
            response.EnsureSuccessStatusCode();
            
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);
            var rpcResponse = JsonSerializer.Deserialize<JsonRpcResponse<TResponse>>(responseContent);
            
            if (rpcResponse.Error != null)
            {
                throw new NeoRpcException(rpcResponse.Error.Code, rpcResponse.Error.Message);
            }
            
            return rpcResponse.Result;
        }
        finally
        {
            _rateLimiter.Release();
        }
    }
}
```

### 4.2 Async Best Practices Implementation

1. **ConfigureAwait(false)**: Used consistently to avoid deadlocks
2. **CancellationToken Support**: All async methods support cancellation
3. **Timeout Handling**: Configurable timeouts with exponential backoff
4. **Resource Disposal**: Proper disposal patterns with `using` statements
5. **Exception Handling**: Async-aware exception handling

```csharp
public async Task<T> ExecuteWithRetryAsync<T>(Func<CancellationToken, Task<T>> operation, 
    CancellationToken cancellationToken = default)
{
    var retryCount = 0;
    var delay = TimeSpan.FromMilliseconds(100);
    
    while (retryCount < _options.Security.MaxRetryAttempts)
    {
        try
        {
            return await operation(cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex) when (IsRetriableException(ex) && retryCount < _options.Security.MaxRetryAttempts - 1)
        {
            _logger.LogWarning(ex, "Operation failed, retrying in {Delay}ms (attempt {RetryCount})", 
                delay.TotalMilliseconds, retryCount + 1);
            
            await Task.Delay(delay, cancellationToken).ConfigureAwait(false);
            delay = TimeSpan.FromMilliseconds(delay.TotalMilliseconds * 2); // Exponential backoff
            retryCount++;
        }
    }
    
    throw new InvalidOperationException($"Operation failed after {_options.Security.MaxRetryAttempts} attempts");
}
```

## 5. Error Handling Strategy

### 5.1 Exception Hierarchy

```csharp
// Base exception for all NeoCSharp errors
public abstract class NeoCSharpException : Exception
{
    protected NeoCSharpException(string message) : base(message) { }
    protected NeoCSharpException(string message, Exception innerException) : base(message, innerException) { }
}

// Specific exception types
public class CryptographicException : NeoCSharpException
{
    public CryptographicException(string message) : base(message) { }
    public CryptographicException(string message, Exception innerException) : base(message, innerException) { }
}

public class NeoRpcException : NeoCSharpException
{
    public int Code { get; }
    public NeoRpcException(int code, string message) : base(message) => Code = code;
}

public class TransactionException : NeoCSharpException
{
    public TransactionException(string message) : base(message) { }
}

public class WalletException : NeoCSharpException
{
    public WalletException(string message) : base(message) { }
}

public class ContractException : NeoCSharpException
{
    public ContractException(string message) : base(message) { }
}
```

### 5.2 Error Handling Patterns

```csharp
// Result pattern for operations that can fail
public class Result<T>
{
    public bool IsSuccess { get; }
    public T Value { get; }
    public string Error { get; }
    public Exception Exception { get; }

    private Result(T value)
    {
        IsSuccess = true;
        Value = value;
    }

    private Result(string error, Exception exception = null)
    {
        IsSuccess = false;
        Error = error;
        Exception = exception;
    }

    public static Result<T> Success(T value) => new Result<T>(value);
    public static Result<T> Failure(string error, Exception exception = null) => new Result<T>(error, exception);
}

// Usage example
public async Task<Result<Transaction>> BuildTransactionAsync(TransactionRequest request)
{
    try
    {
        var transaction = await _transactionBuilder
            .AddTransfer(request.From, request.To, request.Amount)
            .BuildAsync();
        
        return Result<Transaction>.Success(transaction);
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Failed to build transaction");
        return Result<Transaction>.Failure("Transaction building failed", ex);
    }
}
```

## 6. Testing Project Structure

### 6.1 Test Organization

```
tests/
├── NeoCSharp.Tests/                       # Unit tests
│   ├── Crypto/
│   │   ├── ECKeyPairTests.cs
│   │   ├── HashTests.cs
│   │   └── SignatureTests.cs
│   ├── Protocol/
│   │   ├── HttpServiceTests.cs
│   │   └── NeoClientTests.cs
│   ├── Transactions/
│   │   └── TransactionBuilderTests.cs
│   ├── Wallets/
│   │   ├── AccountTests.cs
│   │   └── WalletTests.cs
│   └── TestHelpers/
│       ├── MockHttpClient.cs
│       └── TestDataGenerator.cs
├── NeoCSharp.Integration.Tests/           # Integration tests
│   ├── RealNodeTests.cs
│   └── ContractInteractionTests.cs
└── NeoCSharp.Performance.Tests/           # Performance tests
    ├── CryptoBenchmarks.cs
    └── HttpPerformanceTests.cs
```

### 6.2 Testing Framework Configuration

```xml
<ItemGroup>
  <!-- Core testing framework -->
  <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.10.0" />
  <PackageReference Include="xunit" Version="2.9.0" />
  <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2" />
  
  <!-- Assertion library -->
  <PackageReference Include="FluentAssertions" Version="6.12.0" />
  
  <!-- Mocking framework -->
  <PackageReference Include="Moq" Version="4.20.70" />
  
  <!-- Performance testing -->
  <PackageReference Include="BenchmarkDotNet" Version="0.13.12" />
  
  <!-- Coverage -->
  <PackageReference Include="coverlet.collector" Version="6.0.2" />
</ItemGroup>
```

### 6.3 Test Patterns and Examples

```csharp
public class ECKeyPairTests
{
    [Fact]
    public void GenerateKeyPair_ShouldCreateValidKeyPair()
    {
        // Arrange
        var generator = new ECKeyPairGenerator();

        // Act
        var keyPair = generator.Generate();

        // Assert
        keyPair.Should().NotBeNull();
        keyPair.PrivateKey.Should().NotBeNull();
        keyPair.PublicKey.Should().NotBeNull();
        keyPair.PublicKey.ToString().Should().HaveLength(66); // Compressed public key
    }

    [Theory]
    [InlineData("KxDgvEKzgSBPPfuVfw67oPQBSjidEiqTHURKSDL1R7yGaGYAeellg")]
    [InlineData("5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ")]
    public void ImportFromWIF_ValidWIF_ShouldCreateKeyPair(string wif)
    {
        // Act
        var keyPair = ECKeyPair.FromWIF(wif);

        // Assert
        keyPair.Should().NotBeNull();
        keyPair.ToWIF().Should().Be(wif);
    }
}

[Collection("Integration Tests")]
public class NeoClientIntegrationTests : IDisposable
{
    private readonly INeoClient _client;
    private readonly ITestOutputHelper _output;

    public NeoClientIntegrationTests(ITestOutputHelper output)
    {
        _output = output;
        _client = new NeoClient("http://testnet.example.com:20332");
    }

    [Fact]
    public async Task GetBestBlockHash_ShouldReturnValidHash()
    {
        // Act
        var hash = await _client.GetBestBlockHashAsync();

        // Assert
        hash.Should().NotBeNull();
        hash.ToString().Should().MatchRegex("^0x[0-9a-fA-F]{64}$");
    }

    public void Dispose() => _client?.Dispose();
}
```

## 7. NuGet Package Metadata

### 7.1 Package Configuration

```xml
<PropertyGroup>
  <!-- Package Identity -->
  <PackageId>NeoCSharp</PackageId>
  <Version>1.0.0</Version>
  <Authors>NeoCSharp Contributors</Authors>
  <Company>Neo Project</Company>
  
  <!-- Package Description -->
  <Title>NeoCSharp - Neo Blockchain SDK for .NET</Title>
  <Description>A comprehensive C# library for Neo blockchain development, providing tools for wallet management, smart contract interaction, and transaction building.</Description>
  <Summary>Complete Neo blockchain SDK for .NET applications</Summary>
  
  <!-- Package Metadata -->
  <PackageTags>neo;blockchain;cryptocurrency;smart-contracts;nep;dapp;nep17;nep11;neo3;wallet</PackageTags>
  <PackageProjectUrl>https://github.com/neo-project/NeoCSharp</PackageProjectUrl>
  <RepositoryUrl>https://github.com/neo-project/NeoCSharp</RepositoryUrl>
  <RepositoryType>git</RepositoryType>
  <PackageLicenseExpression>MIT</PackageLicenseExpression>
  <PackageRequireLicenseAcceptance>false</PackageRequireLicenseAcceptance>
  
  <!-- Package Assets -->
  <PackageIcon>icon.png</PackageIcon>
  <PackageReadmeFile>README.md</PackageReadmeFile>
  <PackageReleaseNotes>Initial release with full Neo N3 support</PackageReleaseNotes>
  
  <!-- Symbol Packages -->
  <IncludeSymbols>true</IncludeSymbols>
  <SymbolPackageFormat>snupkg</SymbolPackageFormat>
  
  <!-- Source Link -->
  <PublishRepositoryUrl>true</PublishRepositoryUrl>
  <EmbedUntrackedSources>true</EmbedUntrackedSources>
  <IncludeSourceRevisionInInformationalVersion>true</IncludeSourceRevisionInInformationalVersion>
</PropertyGroup>

<ItemGroup>
  <None Include="README.md" Pack="true" PackagePath="\" />
  <None Include="icon.png" Pack="true" PackagePath="\" Condition="Exists('icon.png')" />
  <PackageReference Include="Microsoft.SourceLink.GitHub" Version="8.0.0" PrivateAssets="All" />
</ItemGroup>
```

### 7.2 Multi-Package Strategy

```
NeoCSharp (Core)                           # Core functionality
├── NeoCSharp.Extensions                   # Optional extensions and utilities
├── NeoCSharp.AspNetCore                   # ASP.NET Core integration
├── NeoCSharp.EntityFramework              # EF Core integration for data persistence
├── NeoCSharp.JsonConverters               # System.Text.Json converters
└── NeoCSharp.Testing                      # Testing utilities and mock objects
```

## 8. Build and Deployment Configuration

### 8.1 MSBuild Configuration

```xml
<!-- Directory.Build.props -->
<Project>
  <PropertyGroup>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <WarningsAsErrors />
    <WarningsNotAsErrors />
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
    <ImplicitUsings>enable</ImplicitUsings>
    
    <!-- Code Analysis -->
    <EnableNETAnalyzers>true</EnableNETAnalyzers>
    <AnalysisLevel>latest</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    
    <!-- Assembly Information -->
    <Company>Neo Project</Company>
    <Copyright>Copyright © Neo Project</Copyright>
    <Product>NeoCSharp</Product>
    
    <!-- Build Configuration -->
    <Deterministic>true</Deterministic>
    <ContinuousIntegrationBuild Condition="'$(GITHUB_ACTIONS)' == 'true'">true</ContinuousIntegrationBuild>
  </PropertyGroup>
  
  <!-- Global Package References -->
  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" Version="3.3.4" PrivateAssets="all" />
    <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0" PrivateAssets="all" />
  </ItemGroup>
</Project>
```

### 8.2 CI/CD Pipeline Configuration

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  release:
    types: [ published ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        dotnet-version: ['8.0.x']
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: ${{ matrix.dotnet-version }}
    
    - name: Restore dependencies
      run: dotnet restore
    
    - name: Build
      run: dotnet build --no-restore --configuration Release
    
    - name: Test
      run: dotnet test --no-build --configuration Release --verbosity normal --collect:"XPlat Code Coverage"
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
    
    - name: Pack
      if: github.event_name == 'release'
      run: dotnet pack --no-build --configuration Release --output ./packages
    
    - name: Publish to NuGet
      if: github.event_name == 'release'
      run: dotnet nuget push "./packages/*.nupkg" --source https://api.nuget.org/v3/index.json --api-key ${{ secrets.NUGET_API_KEY }}
```

### 8.3 Development Tools Configuration

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "NeoCSharp Console Example",
            "type": "coreclr",
            "request": "launch",
            "program": "${workspaceFolder}/examples/NeoCSharp.Examples.Console/bin/Debug/net8.0/NeoCSharp.Examples.Console.dll",
            "args": [],
            "cwd": "${workspaceFolder}/examples/NeoCSharp.Examples.Console",
            "stopAtEntry": false,
            "console": "internalConsole"
        }
    ]
}
```

## 9. Security Considerations for Crypto Operations

### 9.1 Secure Memory Management

```csharp
public class SecureBytes : IDisposable
{
    private readonly byte[] _bytes;
    private readonly GCHandle _handle;
    private bool _disposed;

    public SecureBytes(byte[] bytes)
    {
        _bytes = new byte[bytes.Length];
        Array.Copy(bytes, _bytes, bytes.Length);
        _handle = GCHandle.Alloc(_bytes, GCHandleType.Pinned);
    }

    public ReadOnlySpan<byte> AsSpan() => _disposed ? throw new ObjectDisposedException(nameof(SecureBytes)) : _bytes;

    public void Dispose()
    {
        if (_disposed) return;
        
        // Clear sensitive data
        CryptographicOperations.ZeroMemory(_bytes);
        
        if (_handle.IsAllocated)
        {
            _handle.Free();
        }
        
        _disposed = true;
    }
}
```

### 9.2 Cryptographic Service Implementation

```csharp
public class SecureECKeyPair : IDisposable
{
    private readonly SecureBytes _privateKeyBytes;
    private readonly ECPoint _publicKey;
    private bool _disposed;

    public SecureECKeyPair(byte[] privateKey)
    {
        _privateKeyBytes = new SecureBytes(privateKey);
        _publicKey = ECPoint.FromPrivateKey(privateKey);
    }

    public byte[] Sign(ReadOnlySpan<byte> data)
    {
        if (_disposed) throw new ObjectDisposedException(nameof(SecureECKeyPair));
        
        using var ecdsa = ECDsa.Create();
        ecdsa.ImportECPrivateKey(_privateKeyBytes.AsSpan(), out _);
        return ecdsa.SignData(data, HashAlgorithmName.SHA256);
    }

    public void Dispose()
    {
        if (_disposed) return;
        
        _privateKeyBytes?.Dispose();
        _disposed = true;
    }
}
```

### 9.3 Security Best Practices

1. **Memory Protection**: Use `SecureString` and secure memory allocation
2. **Key Derivation**: Implement PBKDF2 and scrypt for key derivation
3. **Constant-Time Operations**: Use constant-time comparisons for sensitive data
4. **Secure Random**: Use `RandomNumberGenerator` for cryptographic randomness
5. **Input Validation**: Strict validation of all cryptographic inputs
6. **Audit Logging**: Log security-relevant operations (without sensitive data)

```csharp
public static class ConstantTime
{
    public static bool Equals(ReadOnlySpan<byte> left, ReadOnlySpan<byte> right)
    {
        if (left.Length != right.Length)
            return false;

        int result = 0;
        for (int i = 0; i < left.Length; i++)
        {
            result |= left[i] ^ right[i];
        }
        
        return result == 0;
    }
}
```

## 10. Cross-Platform Compatibility (.NET Standard 2.1)

### 10.1 Platform Abstraction

```csharp
// Platform-specific implementations
public interface IPlatformCrypto
{
    byte[] GenerateRandomBytes(int length);
    byte[] ComputeHash(ReadOnlySpan<byte> data, HashAlgorithm algorithm);
    byte[] Sign(ReadOnlySpan<byte> data, ReadOnlySpan<byte> privateKey);
}

#if NET8_0_OR_GREATER
public class ModernPlatformCrypto : IPlatformCrypto
{
    public byte[] GenerateRandomBytes(int length)
    {
        return RandomNumberGenerator.GetBytes(length);
    }
    
    // ... other implementations using modern APIs
}
#endif

#if NETSTANDARD2_1
public class LegacyPlatformCrypto : IPlatformCrypto
{
    private readonly RandomNumberGenerator _rng = RandomNumberGenerator.Create();
    
    public byte[] GenerateRandomBytes(int length)
    {
        var bytes = new byte[length];
        _rng.GetBytes(bytes);
        return bytes;
    }
    
    // ... other implementations using .NET Standard 2.1 APIs
}
#endif
```

### 10.2 Conditional Compilation Strategy

```csharp
public static class PlatformFeatures
{
#if NET8_0_OR_GREATER
    public static bool SupportsSpan => true;
    public static bool SupportsMemory => true;
    public static bool SupportsModernCrypto => true;
#else
    public static bool SupportsSpan => false;
    public static bool SupportsMemory => false;
    public static bool SupportsModernCrypto => false;
#endif
}
```

### 10.3 Package Dependencies by Target

```xml
<ItemGroup Condition="'$(TargetFramework)' == 'net8.0'">
  <!-- Modern .NET packages -->
  <PackageReference Include="System.Text.Json" Version="8.0.5" />
</ItemGroup>

<ItemGroup Condition="'$(TargetFramework)' == 'netstandard2.1'">
  <!-- Compatibility packages for .NET Standard -->
  <PackageReference Include="System.Text.Json" Version="6.0.0" />
  <PackageReference Include="System.Memory" Version="4.5.5" />
  <PackageReference Include="System.Threading.Tasks.Extensions" Version="4.5.4" />
</ItemGroup>

<ItemGroup>
  <!-- Common packages for all targets -->
  <PackageReference Include="BouncyCastle.Cryptography" Version="2.3.1" />
  <PackageReference Include="NBitcoin" Version="7.0.43" />
  <PackageReference Include="Microsoft.Extensions.Logging.Abstractions" Version="8.0.2" />
</ItemGroup>
```

## 11. Performance Considerations

### 11.1 Memory Management

1. **Object Pooling**: Pool frequently allocated objects
2. **Span<T> Usage**: Use spans to avoid allocations where possible
3. **String Interning**: Intern commonly used strings
4. **Lazy Initialization**: Defer expensive operations until needed

```csharp
public class HashCache
{
    private readonly ConcurrentDictionary<string, Hash256> _cache = new();
    private readonly Timer _cleanupTimer;
    
    public Hash256 GetOrCompute(string input, Func<string, Hash256> factory)
    {
        return _cache.GetOrAdd(input, factory);
    }
    
    // Periodic cleanup logic...
}
```

### 11.2 Async Best Practices

1. **ConfigureAwait(false)**: Use consistently in library code
2. **ValueTask Usage**: Use ValueTask for frequently called async methods
3. **Cancellation Support**: Support CancellationToken in all async operations
4. **Connection Pooling**: Reuse HTTP connections

## 12. Documentation Strategy

### 12.1 XML Documentation

```csharp
/// <summary>
/// Represents a Neo blockchain client for interacting with Neo nodes.
/// </summary>
/// <remarks>
/// This client provides methods for querying blockchain data, invoking smart contracts,
/// and submitting transactions to the Neo network.
/// </remarks>
/// <example>
/// <code>
/// var client = new NeoClient("http://localhost:20332");
/// var blockHash = await client.GetBestBlockHashAsync();
/// Console.WriteLine($"Best block: {blockHash}");
/// </code>
/// </example>
public class NeoClient : INeoClient
{
    /// <summary>
    /// Gets the best block hash from the blockchain.
    /// </summary>
    /// <param name="cancellationToken">Cancellation token for the operation.</param>
    /// <returns>A task that represents the asynchronous operation. The task result contains the best block hash.</returns>
    /// <exception cref="NeoRpcException">Thrown when the RPC call fails.</exception>
    public async Task<Hash256> GetBestBlockHashAsync(CancellationToken cancellationToken = default)
    {
        // Implementation...
    }
}
```

### 12.2 README Structure

```markdown
# NeoCSharp - Neo Blockchain SDK for .NET

## Quick Start
## Installation
## Features
## Examples
## Documentation
## Contributing
## License
```

## 13. Migration Strategy from Swift

### 13.1 API Compatibility Mapping

| Swift API | C# API | Notes |
|-----------|--------|-------|
| `NeoRpcClient.build()` | `ServiceCollection.AddNeoCSharp()` | Dependency injection pattern |
| `neow3j.getBlockByHash()` | `client.GetBlockAsync(hash)` | Async/await pattern |
| `ECKeyPair.create()` | `ECKeyPair.Generate()` | Static factory method |
| `Transaction.sign()` | `transaction.SignAsync()` | Async signing |

### 13.2 Breaking Changes Documentation

Document all intentional API differences and provide migration guides for developers familiar with the Swift SDK.

## 14. Conclusion

This architecture design provides a solid foundation for the NeoCSharp SDK that:

- ✅ **Follows .NET Best Practices**: Dependency injection, async/await, proper disposal
- ✅ **Ensures Security**: Secure memory management, constant-time operations
- ✅ **Supports Enterprise Use**: Comprehensive testing, logging, configuration
- ✅ **Maintains Compatibility**: Cross-platform support with .NET Standard 2.1
- ✅ **Enables Future Growth**: Extensible architecture with clear separation of concerns
- ✅ **Provides Developer Experience**: Rich documentation, examples, and tooling support

The architecture balances the mature patterns from the Swift SDK with modern .NET development practices, ensuring both compatibility with the broader Neo ecosystem and excellent developer experience for .NET developers.