remake_find_package(Perl QUIET)
remake_find_executable(groff)

if(PERL_FOUND AND GROFF_FOUND)
  remake_file_configure(shdoc.conf.remake OUTPUT shdoc_config)
  remake_add_documentation(CUSTOM ShDoc
    ${PERL_EXECUTABLE} shdoc.pl -c ${shdoc_config} -t
    INPUT ${CMAKE_SOURCE_DIR}/${REMAKE_PROJECT_SOURCE_DIR}
    TYPES man ascii utf8 html ps)
endif(PERL_FOUND AND GROFF_FOUND)
