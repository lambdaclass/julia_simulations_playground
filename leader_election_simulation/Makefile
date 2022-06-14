define create_data_dir
	if [ -d "./data" ]; then \
        rm -r data; \
		mkdir data; \
		mkdir data/stake; \
		mkdir data/balance; \
		mkdir data/proposals; \
	else \
		mkdir data; \
		mkdir data/stake; \
		mkdir data/balance; \
		mkdir data/proposals; \
    fi
endef

install:
	julia package_manager.jl

run:
	$(call create_data_dir)
	julia voting_simulation.jl
