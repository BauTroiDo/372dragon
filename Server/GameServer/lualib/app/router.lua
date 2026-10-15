local user_router = require("app.routes.user")
local table_router = require("app.routes.table")
local cluster_router = require("app.routes.cluster")
local world_router = require("app.routes.world")

return function(app)
    user_router(app:group("/user"))
    table_router(app:group("/table"))
    cluster_router(app:group("/cluster"))
    world_router(app:group("/world"))
end
