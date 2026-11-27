local s=require("enet_1")
local data={
    time_reconnect=5,
    nickname="SIX SEVEN Я РУССКИИИЙ!!!",
    adress_servers={
        "127.0.0.1:5555",
        "127.0.0.1:4444"
    }
}
local peer
function data.init(peer1)
    peer=peer1
end
function data.meschat(string)
    s.message(peer,"chat_client_all",{string})
end
return data