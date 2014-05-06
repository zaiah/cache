buildopts \
	--from "file,folder,default" \
	--from "@exists,@required,@create,@remove,@update" \
	--from "@needs,@no-longer-needs,@load-needs" \
	--from "@version" \
	--from "@uuid" \
	--from "@description" \
	--from "@summary" \
	--from "@title" \
	--from "@namespace" \
	--from "@filename" \
	--from "@url" \
	--from "@produced-on" \
	--from "@authors" \
	--from "@signature"  \
	--from "@key" \
	--from "@fingerprint" \
	--from "@extra"  \
	--from "@install"  \
	--from "uninstall" \
	--all chain \
	--short-if \
	--summary "A database-less way to manage dependencies." \
	--license mit \
	--library
#	--at chain.sh \
#	--make-exec

