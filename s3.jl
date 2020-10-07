function upload_s3(hash)
    orig_path = @__FILE__
    path = splitext(orig_path)[1] * ".tar.gz"
    run(`tar -czvf $(path) -C $(dirname(orig_path)) $(basename(orig_path))`)

    ENV["BB_HASH"] = get(ENV, "BB_HASH", "01234")
    ENV["PROJ_HASH"] = get(ENV, "PROJ_HASH", "abcde")
    ENV["S3SECRET"] = get(ENV, "S3SECRET", "supersecret")
    ENV["S3KEY"] = get(ENV, "S3KEY", "superkey")

    ACL="x-amz-acl:public-read"
    CONTENT_TYPE="application/x-gtar"
    BUCKET="julia-bb-buildcache"
    BUCKET_PATH="$(ENV["BB_HASH"])/$(ENV["PROJ_HASH"])/$(basename(path))"
    DATE=readchomp(`date -R`)
    S3SIGNATURE=readchomp(pipeline(`echo -en "PUT\n\n$(CONTENT_TYPE)\n$(DATE)\n$(ACL)\n/$(BUCKET)/$(BUCKET_PATH)"`,
                                   `openssl sha1 -hmac "$(ENV["S3SECRET"])" -binary`,
                                   `base64`))
    HOST="$(BUCKET).s3.amazonaws.com"
    @info "Uploading artifact to https://$(HOST)/$(BUCKET_PATH)"
    run(`curl -X PUT -T "$(path)"
            -H "Host: $(HOST)"
            -H "Date: $(DATE)"
            -H "Content-Type: $(CONTENT_TYPE)"
            -H "$(ACL)"
            -H "Authorization: AWS $(ENV["S3KEY"]):$(S3SIGNATURE)"
            "https://$(HOST)/$(BUCKET_PATH)"`)
end

upload_s3("abcde")
