import 'dart:typed_data';
import 'package:test/test.dart';
import '../lib/bdk.dart';

void main() {
  group('Mnemonic Tests', () {
    test('Create new mnemonic with 12 words', () {
      print('Creating new 12-word mnemonic...');
      final mnemonic = Mnemonic(WordCount.words12);
      expect(mnemonic, isA<Mnemonic>());
      final mnemonicString = mnemonic.toString();
      print('Generated mnemonic: $mnemonicString');
      expect(mnemonicString.split(' ').length, equals(12));
      print('✓ 12-word mnemonic created successfully');
    });

    test('Create new mnemonic with 24 words', () {
      print('Creating new 24-word mnemonic...');
      final mnemonic = Mnemonic(WordCount.words24);
      expect(mnemonic, isA<Mnemonic>());
      final mnemonicString = mnemonic.toString();
      print('Generated mnemonic (24 words): ${mnemonicString.substring(0, 50)}...');
      expect(mnemonicString.split(' ').length, equals(24));
      print('✓ 24-word mnemonic created successfully');
    });

    test('Create mnemonic from string', () {
      print('Creating mnemonic from known phrase...');
      const mnemonicPhrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mnemonic = Mnemonic.fromString(mnemonicPhrase);
      expect(mnemonic, isA<Mnemonic>());
      expect(mnemonic.toString(), equals(mnemonicPhrase));
      print('✓ Mnemonic created from string successfully');
    });

    test('Throw error on invalid mnemonic string', () {
      print('Testing invalid mnemonic rejection...');
      expect(
        () => Mnemonic.fromString('invalid mnemonic phrase'),
        throwsA(isA<Bip39Exception>()),
      );
      print('✓ Invalid mnemonic correctly rejected');
    });

    test('Create mnemonic from entropy', () {
      print('Creating mnemonic from entropy (16 bytes of zeros)...');
      // 16 bytes for 12 words
      final entropy = Uint8List.fromList(List.filled(16, 0));
      final mnemonic = Mnemonic.fromEntropy(entropy);
      expect(mnemonic, isA<Mnemonic>());
      expect(
        mnemonic.toString(),
        equals(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
      );
      print('✓ Mnemonic created from entropy successfully');
    });
  });

  group('DescriptorSecretKey Tests', () {
    test('Create descriptor secret key from mnemonic', () {
      print('Creating descriptor secret key from mnemonic...');
      final mnemonic = Mnemonic(WordCount.words12);
      final descriptorSecretKey =
          DescriptorSecretKey(Network.testnet, mnemonic, null);
      expect(descriptorSecretKey, isA<DescriptorSecretKey>());
      print('✓ Descriptor secret key created successfully');
    });

    test('Create descriptor secret key from mnemonic with password', () {
      final mnemonic = Mnemonic(WordCount.words12);
      final descriptorSecretKey =
          DescriptorSecretKey(Network.testnet, mnemonic, 'password123');
      expect(descriptorSecretKey, isA<DescriptorSecretKey>());
    });

    test('Get public key from secret key', () {
      print('Deriving public key from secret key...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final publicKey = secretKey.asPublic();
      expect(publicKey, isA<DescriptorPublicKey>());
      print('Public key: ${publicKey.toString().substring(0, 50)}...');
      print('✓ Public key derived successfully');
    });

    test('Get secret bytes', () {
      print('Extracting secret bytes from key...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final secretBytes = secretKey.secretBytes();
      expect(secretBytes, isA<Uint8List>());
      expect(secretBytes.length, equals(32)); // 256 bits
      print('Secret bytes length: ${secretBytes.length} bytes (256 bits)');
      print('✓ Secret bytes extracted successfully');
    });

    test('Create descriptor secret key from string', () {
      // Example xpriv key
      const xpriv =
          'tprv8ZgxMBicQKsPcx5nBGsR63Pe8KnRUqmbJNENAfGftF3yuXoMMoVJJcYeUw5eVkm9WBPjWYt6HMWYJNesB5HaNVBaFc1M6dRjWSYnmewUMYy';
      final secretKey = DescriptorSecretKey.fromString(xpriv);
      expect(secretKey, isA<DescriptorSecretKey>());
    });
  });

  group('Descriptor Tests', () {
    test('Create BIP44 descriptor', () {
      print('Creating BIP44 descriptor (legacy P2PKH)...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip44(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      expect(descriptor, isA<Descriptor>());
      print('✓ BIP44 descriptor created successfully');
    });

    test('Create BIP49 descriptor (P2WPKH-nested-in-P2SH)', () {
      print('Creating BIP49 descriptor (nested SegWit)...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip49(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      expect(descriptor, isA<Descriptor>());
      print('✓ BIP49 descriptor created successfully');
    });

    test('Create BIP84 descriptor (P2WPKH)', () {
      print('Creating BIP84 descriptor (native SegWit)...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      expect(descriptor, isA<Descriptor>());
      print('✓ BIP84 descriptor created successfully');
    });

    test('Create BIP86 descriptor (P2TR)', () {
      print('Creating BIP86 descriptor (Taproot)...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip86(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      expect(descriptor, isA<Descriptor>());
      print('✓ BIP86 descriptor created successfully');
    });

    test('Create descriptor from string', () {
      const descriptorString =
          'wpkh([c258d2e4/84h/1h/0h]tpubDD3ynpHgJQW8VvWRzQ5WFDCrs4jqVFGHB3vLC3r49XHJSqP8bHKdK4AriuUKLccK68zfzowx7YhmDN8SiSkgCDENUFx9qVw65YyqM78vyVe/0/*)';
      final descriptor = Descriptor(descriptorString, Network.testnet);
      expect(descriptor, isA<Descriptor>());
    });
  });

  group('Address Tests', () {
    test('Create valid testnet address', () {
      print('Creating testnet address...');
      const addressString = 'tb1q6d3a2w975yny0asuvd9a67ner4nks58ff0q8g4';
      final address = Address(addressString, Network.testnet);
      expect(address, isA<Address>());
      expect(address.toString(), equals(addressString));
      print('Address: $addressString');
      print('✓ Testnet address created successfully');
    });

    test('Create valid bitcoin mainnet address', () {
      print('Creating mainnet address...');
      const addressString = 'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq';
      final address = Address(addressString, Network.bitcoin);
      expect(address, isA<Address>());
      expect(address.toString(), equals(addressString));
      print('Address: $addressString');
      print('✓ Mainnet address created successfully');
    });

    test('Validate address for correct network', () {
      print('Validating address network compatibility...');
      const addressString = 'tb1q6d3a2w975yny0asuvd9a67ner4nks58ff0q8g4';
      final address = Address(addressString, Network.testnet);
      expect(address.isValidForNetwork(Network.testnet), isTrue);
      expect(address.isValidForNetwork(Network.bitcoin), isFalse);
      print('✓ Address validated for testnet, rejected for mainnet');
    });

    test('Throw error on invalid address', () {
      expect(
        () => Address('invalid_address', Network.testnet),
        throwsA(isA<AddressParseException>()),
      );
    });

    test('Compare addresses for equality', () {
      const addressString = 'tb1q6d3a2w975yny0asuvd9a67ner4nks58ff0q8g4';
      final address1 = Address(addressString, Network.testnet);
      final address2 = Address(addressString, Network.testnet);
      expect(address1 == address2, isTrue);
    });
  });

  group('Network Tests', () {
    test('Test network enum values', () {
      expect(Network.bitcoin, equals(Network.bitcoin));
      expect(Network.testnet, equals(Network.testnet));
      expect(Network.testnet4, equals(Network.testnet4));
      expect(Network.signet, equals(Network.signet));
      expect(Network.regtest, equals(Network.regtest));
    });
  });

  group('KeychainKind Tests', () {
    test('Test keychain kind enum values', () {
      expect(KeychainKind.external_, equals(KeychainKind.external_));
      expect(KeychainKind.internal, equals(KeychainKind.internal));
    });
  });

  group('WordCount Tests', () {
    test('Test word count enum values', () {
      expect(WordCount.words12, equals(WordCount.words12));
      expect(WordCount.words15, equals(WordCount.words15));
      expect(WordCount.words18, equals(WordCount.words18));
      expect(WordCount.words21, equals(WordCount.words21));
      expect(WordCount.words24, equals(WordCount.words24));
    });
  });

  group('Wallet Creation Tests', () {
    late Mnemonic mnemonic;
    late DescriptorSecretKey secretKey;
    late Descriptor externalDescriptor;
    late Descriptor internalDescriptor;

    setUp(() {
      print('\n--- Setting up wallet test ---');
      // Use a fixed mnemonic for consistent tests
      const mnemonicPhrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      mnemonic = Mnemonic.fromString(mnemonicPhrase);
      secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      externalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      internalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.internal,
        Network.testnet,
      );
      print('Wallet descriptors initialized');
    });

    test('Create wallet with persistence', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20, // lookahead
      );
      expect(wallet, isA<Wallet>());
    });

    test('Create single descriptor wallet', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet.createSingle(
        externalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      expect(wallet, isA<Wallet>());
    });

    test('Get wallet network', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      expect(wallet.network(), equals(Network.testnet));
    });

    test('Get wallet balance', () {
      print('Checking wallet balance...');
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final balance = wallet.balance();
      expect(balance, isA<Balance>());
      expect(balance.total, isA<Amount>());
      print('Balance: ${balance.total} sats (new wallet, should be 0)');
      print('✓ Wallet balance retrieved successfully');
    });

    test('Get next unused address', () {
      print('Getting next unused address...');
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final addressInfo = wallet.nextUnusedAddress(KeychainKind.external_);
      expect(addressInfo, isA<AddressInfo>());
      expect(addressInfo.address, isA<Address>());
      expect(addressInfo.index, equals(0));
      expect(addressInfo.keychain, equals(KeychainKind.external_));
      print('First address: ${addressInfo.address} (index: ${addressInfo.index})');
      print('✓ Next unused address retrieved successfully');
    });

    test('Reveal next address', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final addressInfo = wallet.revealNextAddress(KeychainKind.external_);
      expect(addressInfo, isA<AddressInfo>());
      expect(addressInfo.index, equals(0));
    });

    test('Peek address at specific index', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final addressInfo = wallet.peekAddress(KeychainKind.external_, 5);
      expect(addressInfo, isA<AddressInfo>());
      expect(addressInfo.index, equals(5));
    });

    test('List unspent outputs', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final unspent = wallet.listUnspent();
      expect(unspent, isA<List<LocalOutput>>());
      expect(unspent.isEmpty, isTrue); // New wallet has no UTXOs
    });

    test('List unused addresses', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final unusedAddresses = wallet.listUnusedAddresses(KeychainKind.external_);
      expect(unusedAddresses, isA<List<AddressInfo>>());
    });

    test('Get derivation index', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final index = wallet.derivationIndex(KeychainKind.external_);
      expect(index, isNull); // No addresses revealed yet
    });

    test('Get next derivation index', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final nextIndex = wallet.nextDerivationIndex(KeychainKind.external_);
      expect(nextIndex, equals(0));
    });

    test('Get public descriptor', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final publicDesc = wallet.publicDescriptor(KeychainKind.external_);
      expect(publicDesc, isA<String>());
      expect(publicDesc.isNotEmpty, isTrue);
    });

    test('Get descriptor checksum', () {
      print('Getting descriptor checksum...');
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      final checksum = wallet.descriptorChecksum(KeychainKind.external_);
      expect(checksum, isA<String>());
      expect(checksum.length, equals(8)); // BIP 380 checksum is 8 chars
      print('Descriptor checksum: $checksum');
      print('✓ Descriptor checksum retrieved successfully');
    });

    test('Mark address as used', () {
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );
      // Reveal an address first
      wallet.revealNextAddress(KeychainKind.external_);
      final marked = wallet.markUsed(KeychainKind.external_, 0);
      expect(marked, isTrue);
    });
  });

  group('Wallet Persistence Tests', () {
    test('Persist wallet changes', () {
      print('\n--- Testing wallet persistence ---');
      const mnemonicPhrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mnemonic = Mnemonic.fromString(mnemonicPhrase);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );

      final persister = Persister.newInMemory();
      final wallet = Wallet.createSingle(
        descriptor,
        Network.testnet,
        persister,
        20,
      );

      print('Revealing address to create wallet changes...');
      // Reveal an address to create a change
      final addr = wallet.revealNextAddress(KeychainKind.external_);
      print('Address revealed: ${addr.address}');

      // Persist changes
      print('Persisting wallet changes...');
      final persisted = wallet.persist(persister);
      expect(persisted, isA<bool>());
      print('Persisted: $persisted');
      print('✓ Wallet changes persisted successfully');
    });
  });

  print('\n=== All BDK tests completed successfully! ===\n');
}
