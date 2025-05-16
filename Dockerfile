FROM hugomods/hugo 

WORKDIR /site

COPY . .

ENTRYPOINT ["hugo"]
CMD ["--baseURL=https://onurhanak.com/", "--minify"]
