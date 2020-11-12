.PRECIOUS: %.4gl
#export FGLPROFILE=fglprofile
%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -r -M -Wall -Wno-stdsql -Wno-case $*

ALLMODULES = $(patsubst %.4gl, %.42m, $(wildcard *.4gl))
MODULES=$(filter-out utils.42m,$(ALLMODULES))
ALLFORMS   = $(patsubst %.per, %.42f, $(wildcard *.per))
FORMS=$(filter-out customers.42f,$(ALLFORMS))

all: stores.sch customers.42f cols_customer.4gl $(FORMS) utils.42m $(MODULES)

$(FORMS) $(MODULES): stores.sch cols_customer.4gl

run: all stores.sch $(MODULES) $(FORMS)
	fglrun customers

test.42m: utils.42m

cols_customer.4gl: customers.42f
	#tools/gen_col_names stores.sch customer cols_customer.4gl
	tools/gen_form_names customers.42f cols_customer.4gl

aui_const.4gl:
	tools/gen_aui_const

sql2array: stores.sch sql2array.42m utils.42m
	fglrun $@

stores.sch: utils.42m
	stores/mkstores

utils.42m: aui_const.4gl

interface: interface.42m
	fglrun $@

customer_reflect: customer_reflect.42m
	fglrun $@

classicINPUT.42m: utils_customer.42m

classicINPUT: classicINPUT.42m
	fglrun $@

dynINPUT.42m: utils_customer.42m

dynINPUT: dynINPUT.42m
	fglrun $@

appINPUT.42m: libINPUT.42m utils_customer.42m

appINPUT: appINPUT.42m
	fglrun $@

classicDA.42m: libDA.42m utils_customer.42m

classicDA: classicDA.42m
	fglrun $@

appDA.42m: libDA.42m utils_customer.42m

appDA: appDA.42m
	fglrun $@

clean::
	$(MAKE) -C stores clean
	$(MAKE) -C tools clean
	$(RM) -f stores.dbs stores.sch
	$(RM) -f *.42? cols_customer.4gl aui_const.4gl

echo:
	@echo "ALLMODULES:$(ALLMODULES)"
	@echo "MODULES:$(MODULES)"
	@echo "ALLFORMS:$(ALLFORMS)"
	@echo "FORMS:$(FORMS)"

