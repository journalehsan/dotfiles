function gemini-proxy --wraps='torsocks gemini' --description 'alias gemini-proxy torsocks gemini'
    torsocks gemini $argv
end
