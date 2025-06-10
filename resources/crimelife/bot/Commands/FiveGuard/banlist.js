const {
  SlashCommandBuilder,
  EmbedBuilder,
  ButtonBuilder,
  ButtonStyle,
  ActionRowBuilder,
} = require("discord.js");

const { readFileSync } = require("fs");

const { LANGUAGE, PERMISSIONS, FIVEGUARD_RESOURCE_NAME } = require("../../config.json");

module.exports = {
  data: new SlashCommandBuilder()
    .setName("fgbanlist")
    .setDescription(LANGUAGE.BANLIST.DESCRIPTION),
  async execute(interaction, client) {
    const roles = PERMISSIONS.BANLIST;
    const memberRoles = interaction.member.roles.cache.map((role) => role.id);

    if (!roles.some((roleId) => memberRoles.includes(roleId))) {
      return interaction.reply({
        embeds: [
          new EmbedBuilder()
            .setColor("Red")
            .setTimestamp()
            .setDescription(LANGUAGE.NO_PERMISSION_INFO),
        ],
      });
    }
    const bansjson = JSON.parse(readFileSync(`${GetResourcePath(FIVEGUARD_RESOURCE_NAME)}/bans.json`, { encoding: "utf8" }));
    const FirstBanID = Object.keys(bansjson)[0];
    const BanData = bansjson[FirstBanID];
    const embed = new EmbedBuilder()
      .setColor("Green")
      .setTitle(`Data for Ban ID: ${FirstBanID}`)
      .setDescription(
        `**__Name:__** \`${BanData.name}\`\n**__Ban Grund:__** \`${BanData.reason}\`\n**__Discord:__** \`${BanData.discord}\`\n**__License:__** \`${BanData.license}\`\n**__Steam:__** \`${BanData.steam}\`\n**__Manual Ban:__** \`${BanData.manual}\``
      )
      .setTimestamp();

    const nextButton = new ButtonBuilder()
      .setStyle(ButtonStyle.Secondary)
      .setLabel("▶")
      .setCustomId(`next`);

    client.UserBanLists.set(interaction.user.id, 0);

    const previousButton = new ButtonBuilder()
      .setStyle(ButtonStyle.Secondary)
      .setLabel("◀")
      .setCustomId("previous")
      .setDisabled(true);

    const aR = new ActionRowBuilder().addComponents(previousButton, nextButton);

    await interaction.reply({ embeds: [embed], components: [aR] });
  },
};
