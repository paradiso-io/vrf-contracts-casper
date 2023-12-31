PINNED_TOOLCHAIN := $(shell cat rust-toolchain)
prepare:
	rustup target add wasm32-unknown-unknown
	rustup component add clippy --toolchain ${PINNED_TOOLCHAIN}
	rustup component add rustfmt --toolchain ${PINNED_TOOLCHAIN}

build-all-contracts: build-block-hash-store build-vrf-coordinator build-test-session
	mkdir -p target
	cp target/wasm32-unknown-unknown/release/*.wasm target/
	cp target/wasm32-unknown-unknown/release/*.wasm tests/wasm

build-block-hash-store:	
	cargo build --release -p block-hash-store --target wasm32-unknown-unknown
	wasm-strip target/wasm32-unknown-unknown/release/block-hash-store.wasm

build-vrf-coordinator:	
	cargo build --release -p vrf-coordinator --target wasm32-unknown-unknown
	wasm-strip target/wasm32-unknown-unknown/release/vrf-coordinator.wasm

build-test-session:	
	cargo build --release -p test-session --target wasm32-unknown-unknown
	wasm-strip target/wasm32-unknown-unknown/release/test-session.wasm

test: build-all-contracts test-only
test-fast: build-all-contracts test-only

test-only: 
	cd tests && rm -f gasStats.txt 
	cp tests/cep18.wasm tests/wasm/
	cp tests/get-session.wasm tests/wasm/
	cd tests && cargo test -- --test-threads 1

clippy:
	cd block-hash-store && cargo clippy --all-targets -- -D warnings
	cd common && cargo clippy --all-targets -- -D warnings
	cd vrf-coordinator && cargo clippy --all-targets -- -D warnings
	cd tests && cargo clippy --all-targets -- -D warnings

check-lint: clippy
	cd block-hash-store && cargo fmt -- --check
	cd common && cargo fmt -- --check
	cd vrf-coordinator && cargo fmt -- --check
	cd tests && cargo fmt -- --check

lint: clippy
	cd block-hash-store && cargo fmt
	cd common && cargo fmt
	cd vrf-coordinator && cargo fmt
	cd tests && cargo fmt

clean:
	rm -rf target
	cd block-hash-store && cargo clean
	cd vrf-coordinator && cargo clean
	rm -rf tests/wasm
