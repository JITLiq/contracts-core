include .env

deploy_src:
	@forge script script/deploy_Source.s.sol:DeploySource --rpc-url ${ARB_RPC} --private-key ${PRIVATE_KEY} --sig "run()" --slow -vvvv --broadcast

deploy_dest:
	@forge script script/deploy_Dest.s.sol:DeployDest --rpc-url ${BASE_RPC} --private-key ${PRIVATE_KEY} --sig "run()" --slow -vvvv --broadcast