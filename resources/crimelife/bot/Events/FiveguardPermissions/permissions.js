const config = require("../../config.json");

module.exports = {
  name: "ready",
  async execute(client) {
    if (config.IN_GAME_PERMISSIONS.ENABLED) {
      const event =
        (config.IN_GAME_PERMISSIONS.FRAMEWORK == "ESX" && "esx:playerLoaded") ||
        (config.IN_GAME_PERMISSIONS.FRAMEWORK == "QB" &&
          "QBCore:Server:OnPlayerLoaded");

      const g = await client.guilds.cache.get(
        config.IN_GAME_PERMISSIONS.GUILD_ID
      );

      on(event, async (id) => {
        const newid = source || id;
        const discord = GetPlayerIdentifierByType(newid, "discord");
        if (!discord)
          return console.error(
            `Player: ${newid} Doesn't Have Discord Identifier!`
          );
        const d = discord.replace("discord:", "");
        if (!g) return console.error("You put Wrong Guild ID in config.json!");
        const member = await g.members.cache.get(d);
        const memberRoles = member.roles.cache.map((role) => role.id);
        Object.keys(config.IN_GAME_PERMISSIONS.PERMISSIONS).some((roleId) => {
          if (memberRoles.includes(roleId)) {
            if (config.IN_GAME_PERMISSIONS.SHOW_LOADED_INFO)
              print(
                `^3Permissions granted to player: ${GetPlayerName(
                  newid
                )} (${newid})^0`
              );
            ExecuteCommand(
              `add_principal identifier.${GetPlayerIdentifier(
                newid,
                0
              )} group.superPermissions`
            );
          }
        });
      });
    }
  },
};
