.PHONY: perf perffull perf13 measure memory clean

RECORD=perf record -F2000 --call-graph dwarf,16000 --
FLAMEGRAPH=perf script | ~/FlameGraph/stackcollapse-perf.pl | ~/FlameGraph/flamegraph.pl >
MEMUSAGE=/usr/bin/env time -f %M
BENCH:=./target/release/rustls-bench
PROVIDER:=aws-lc-rs

perf: $(BENCH)
	$(RECORD) $(BENCH) bulk TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
	$(FLAMEGRAPH) perf-aes128-rustls.svg

perffull: $(BENCH)
	$(RECORD) $(BENCH) bulk TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$(FLAMEGRAPH) perf-aes256-rustls.svg
	$(RECORD) $(BENCH) bulk TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
	$(FLAMEGRAPH) perf-chacha-rustls.svg
	$(RECORD) $(BENCH) handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$(FLAMEGRAPH) perf-fullhs-rustls.svg
	$(RECORD) $(BENCH) handshake-resume TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$(FLAMEGRAPH) perf-resume-rustls.svg
	$(RECORD) $(BENCH) handshake-ticket TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$(FLAMEGRAPH) perf-ticket-rustls.svg

perf13:
	$(RECORD) $(BENCH) handshake-ticket TLS13_AES_256_GCM_SHA384
	$(FLAMEGRAPH) perf-ticket13-rustls.svg

measure: $(BENCH)
	$^ bulk TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
	$^ bulk TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ bulk TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
	$^ --key-type rsa2048 bulk TLS13_AES_256_GCM_SHA384
	$^ handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
	$^ handshake-resume TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ handshake-ticket TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ handshake TLS13_AES_256_GCM_SHA384
	$^ handshake-resume TLS13_AES_256_GCM_SHA384
	$^ handshake-ticket TLS13_AES_256_GCM_SHA384

verdict-bench: $(BENCH)
	@echo '\begin{tabular}{lrrr}'
	@echo 'Implementation & RSA & P256 & P384 \\'
	@echo '\hline'

# With a mix of AWS-LC and libcrux
	@cargo build --profile=bench -p rustls-bench --features $(PROVIDER)

	@echo -n 'V/Chrome$$^\diamond$$'
	@echo -n ' &' $$($^ --validator verdict-chrome --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-chrome --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
# @echo -n ' &' $$($^ --validator verdict-chrome --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' & -'
	@echo ' \\'

	@echo -n 'V/Firefox$$^\diamond$$'
	@echo -n ' &' $$($^ --validator verdict-firefox --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-firefox --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
# @echo -n ' &' $$($^ --validator verdict-firefox --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' & -'
	@echo ' \\'

	@echo -n 'V/OpenSSL$$^\diamond$$'
	@echo -n ' &' $$($^ --validator verdict-openssl --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-openssl --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
# @echo -n ' &' $$($^ --validator verdict-openssl --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' & -'
	@echo ' \\'

# With AWS-LC
	@cargo build --profile=bench -p rustls-bench --features $(PROVIDER) --features rustls/verdict-aws-lc

	@echo -n 'V/Chrome$$^\star$$'
	@echo -n ' &' $$($^ --validator verdict-chrome --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-chrome --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-chrome --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo ' \\'

	@echo -n 'V/Firefox$$^\star$$'
	@echo -n ' &' $$($^ --validator verdict-firefox --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-firefox --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-firefox --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo ' \\'

	@echo -n 'V/OpenSSL$$^\star$$'
	@echo -n ' &' $$($^ --validator verdict-openssl --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-openssl --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --validator verdict-openssl --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo ' \\'

	@echo -n 'Baseline'
	@echo -n ' &' $$($^ --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo -n ' &' $$($^ --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}')
	@echo ' \\'

	@echo '\end{tabular}'

# @echo "Verdict (AWS-LC) RSA 2048"
# @$^ --validator verdict-chrome --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 | awk '{print $$(NF-1)}'

# @$^ --validator verdict-firefox --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384

# @echo "Verdict (AWS-LC) ECDSA-P256"
# @$^ --validator verdict-chrome --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-firefox --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384

# @echo "Verdict (AWS-LC) ECDSA-P384"
# @$^ --validator verdict-chrome --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-firefox --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384

# cargo build --profile=bench -p rustls-bench --features $(PROVIDER)

# @echo "Verdict RSA 2048"
# @$^ --validator verdict-chrome --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-firefox --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384

# @echo "Verdict ECDSA-P256"
# @$^ --validator verdict-chrome --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-firefox --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384

# @echo "Verdict ECDSA-P384"
# @$^ --validator verdict-chrome --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-firefox --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator verdict-openssl --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384

# @echo "Baseline"
# @$^ --validator default --key-type rsa2048 --api unbuffered handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
# @$^ --validator default --key-type ecdsa-p256 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
# @$^ --validator default --key-type ecdsa-p384 --api unbuffered handshake TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384


memory: $(BENCH)
	$(MEMUSAGE) $^ memory TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 100
	$(MEMUSAGE) $^ memory TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 1000
	$(MEMUSAGE) $^ memory TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 5000
	$(MEMUSAGE) $^ memory TLS13_AES_256_GCM_SHA384 100
	$(MEMUSAGE) $^ memory TLS13_AES_256_GCM_SHA384 1000
	$(MEMUSAGE) $^ memory TLS13_AES_256_GCM_SHA384 5000

threads: $(BENCH)
	for thr in $(shell admin/threads-seq.rs) ; do \
	  $^ --threads $$thr handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 ; \
	  $^ --threads $$thr handshake-resume TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 ; \
	  $^ --threads $$thr handshake-ticket TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 ; \
	  $^ --key-type rsa2048 --threads $$thr handshake TLS13_AES_256_GCM_SHA384 ; \
	  $^ --threads $$thr handshake-ticket TLS13_AES_256_GCM_SHA384 ; \
	  $^ --threads $$thr bulk TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 ; \
	  $^ --key-type rsa2048 --threads $$thr bulk TLS13_AES_256_GCM_SHA384 ; \
	done

thread-latency: $(BENCH)
	$^ --threads $$(nproc) --api buffered --key-type rsa2048 --latency-prefix latency-fullhs-tls12 handshake TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ --threads $$(nproc) --api buffered --key-type rsa2048 --latency-prefix latency-fullhs-tls13 handshake TLS13_AES_256_GCM_SHA384
	$^ --threads $$(nproc) --api buffered --key-type rsa2048 --latency-prefix latency-resume-tls12 handshake-resume TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	$^ --threads $$(nproc) --api buffered --key-type rsa2048 --latency-prefix latency-resume-tls13 handshake-ticket TLS13_AES_256_GCM_SHA384

clean:
	rm -f perf-*.svg
	cargo clean

$(BENCH): .FORCE
	cargo build --profile=bench -p rustls-bench --features $(PROVIDER)

.FORCE:
