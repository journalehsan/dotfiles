function docura_build_env
    set -gx DROPBOX_CLIENT_ID "oni7s2m0zhzjqb1"
    set -gx DROPBOX_CLIENT_SECRET "r9oyjntvotwlp4x"
    set -gx DROPBOX_REDIRECT_URI "https://wof-softwares.github.io/Docura/oauth-redirect.html"
    
    echo "✅ Docura Dropbox environment variables loaded!"
    echo "  DROPBOX_CLIENT_ID: $DROPBOX_CLIENT_ID"
    echo "  DROPBOX_REDIRECT_URI: $DROPBOX_REDIRECT_URI"
end
