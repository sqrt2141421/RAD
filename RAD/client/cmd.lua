local cmd_out=love.thread.getChannel("cmd")
while true do
    local com=io.read()
    if not com then break end
    cmd_out:push(com)
end