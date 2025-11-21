import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bdk_dart/bdk.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('BDK iOS Integration Tests', () {
    testWidgets('Create new mnemonic with 12 words', (tester) async {
      print('Creating new 12-word mnemonic on iOS...');
      final mnemonic = Mnemonic(WordCount.words12);
      expect(mnemonic, isA<Mnemonic>());
      final mnemonicString = mnemonic.toString();
      print('Generated mnemonic: $mnemonicString');
      expect(mnemonicString.split(' ').length, equals(12));
      print('✓ 12-word mnemonic created successfully on iOS');
    });

    testWidgets('Create new mnemonic with 24 words', (tester) async {
      print('Creating new 24-word mnemonic on iOS...');
      final mnemonic = Mnemonic(WordCount.words24);
      expect(mnemonic, isA<Mnemonic>());
      final mnemonicString = mnemonic.toString();
      print('Generated mnemonic (24 words): ${mnemonicString.substring(0, 50)}...');
      expect(mnemonicString.split(' ').length, equals(24));
      print('✓ 24-word mnemonic created successfully on iOS');
    });

    testWidgets('Create mnemonic from string', (tester) async {
      print('Creating mnemonic from known phrase on iOS...');
      const mnemonicPhrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mnemonic = Mnemonic.fromString(mnemonicPhrase);
      expect(mnemonic, isA<Mnemonic>());
      expect(mnemonic.toString(), equals(mnemonicPhrase));
      print('✓ Mnemonic created from string successfully on iOS');
    });

    testWidgets('Create mnemonic from entropy', (tester) async {
      print('Creating mnemonic from entropy (16 bytes of zeros) on iOS...');
      final entropy = Uint8List.fromList(List.filled(16, 0));
      final mnemonic = Mnemonic.fromEntropy(entropy);
      expect(mnemonic, isA<Mnemonic>());
      expect(
        mnemonic.toString(),
        equals(
            'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about'),
      );
      print('✓ Mnemonic created from entropy successfully on iOS');
    });

    testWidgets('Create descriptor secret key from mnemonic', (tester) async {
      print('Creating descriptor secret key from mnemonic on iOS...');
      final mnemonic = Mnemonic(WordCount.words12);
      final descriptorSecretKey =
          DescriptorSecretKey(Network.testnet, mnemonic, null);
      expect(descriptorSecretKey, isA<DescriptorSecretKey>());
      print('✓ Descriptor secret key created successfully on iOS');
    });

    testWidgets('Get public key from secret key', (tester) async {
      print('Deriving public key from secret key on iOS...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final publicKey = secretKey.asPublic();
      expect(publicKey, isA<DescriptorPublicKey>());
      print('Public key: ${publicKey.toString().substring(0, 50)}...');
      print('✓ Public key derived successfully on iOS');
    });

    testWidgets('Create BIP84 descriptor', (tester) async {
      print('Creating BIP84 descriptor (native SegWit) on iOS...');
      final mnemonic = Mnemonic(WordCount.words12);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final descriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      expect(descriptor, isA<Descriptor>());
      print('✓ BIP84 descriptor created successfully on iOS');
    });

    testWidgets('Create and use wallet', (tester) async {
      print('Creating wallet on iOS...');
      const mnemonicPhrase =
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      final mnemonic = Mnemonic.fromString(mnemonicPhrase);
      final secretKey = DescriptorSecretKey(Network.testnet, mnemonic, null);
      final externalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        Network.testnet,
      );
      final internalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.internal,
        Network.testnet,
      );

      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        Network.testnet,
        persister,
        20,
      );

      print('Getting wallet balance on iOS...');
      final balance = wallet.balance();
      expect(balance, isA<Balance>());
      print('Balance: ${balance.total}');

      print('Getting next unused address on iOS...');
      final addressInfo = wallet.nextUnusedAddress(KeychainKind.external_);
      expect(addressInfo, isA<AddressInfo>());
      expect(addressInfo.address, isA<Address>());
      print('First address: ${addressInfo.address} (index: ${addressInfo.index})');

      print('✓ Wallet created and used successfully on iOS');
    });
  });
}
