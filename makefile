include .env

deploy:
	@forge script script/Deploy.s.sol:Deploy --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --sig "run()" --slow -vvvv --broadcast
