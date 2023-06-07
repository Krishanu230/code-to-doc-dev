# Container image that runs your code
FROM public.ecr.aws/t7d0n7r6/knowl-code-to-doc-manual:latest
WORKDIR /usr/app
ENTRYPOINT ["./start_doc_gen.sh"]
