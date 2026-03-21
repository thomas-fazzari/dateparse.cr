test:
	crystal spec

fmt:
	crystal tool format src/ spec/

lint:
	./bin/ameba

clean:
	rm -rf lib/ .shards/
