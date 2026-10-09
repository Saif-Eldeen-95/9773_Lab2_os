dir ?= monitored
malicious_dir ?= quarantine
interval ?= 2

all: antivirus

prebuild:
	mkdir -p $(dir) $(malicious_dir)

antivirus: prebuild
	chmod +x antivirusd.sh
	./antivirusd.sh $(dir) $(malicious_dir) $(interval)

restore: prebuild
	chmod +x restore.sh
	./restore.sh $(dir) $(malicious_dir)

clean:
	rm -f directory-info.last directory-info.new

.PHONY: all prebuild antivirus restore clean