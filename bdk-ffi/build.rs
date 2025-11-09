fn main() {
    uniffi::generate_scaffolding("src/bdkffi.udl").unwrap();
    uniffi_dart::generate_scaffolding("src/bdkffi.udl".into()).unwrap();
}
