const {
  EmbedBuilder,
  ButtonBuilder,
  Client,
  ButtonStyle,
  ActionRowBuilder,
  ButtonInteraction,
} = require("discord.js");

const { readFileSync } = require("fs");

const { LANGUAGE, PERMISSIONS, FIVEGUARD_RESOURCE_NAME } = require("../../config.json");

module.exports = {
  name: "interactionCreate",
  /**
   *
   * @param {ButtonInteraction} interaction
   * @param {Client} client
   * @returns
   */
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
    if (!interaction.isButton()) return;

    const { customId } = interaction;
    const bansjson = JSON.parse(readFileSync(`${GetResourcePath(FIVEGUARD_RESOURCE_NAME)}/bans.json`, { encoding: "utf8" }));
    const page = client.UserBanLists.get(interaction.user.id);
    if (page == null) {
      return interaction.update({
        embeds: [
          new EmbedBuilder()
            .setColor("Red")
            .setDescription(`Error vom Server.`),
        ],
        components: [],
      });
    }
    if (customId === "next") {
      const CurrentPage = page + 1;
      const CurrentBanID = Object.keys(bansjson)[CurrentPage];
      const BanData = bansjson[CurrentBanID];
      const embed = new EmbedBuilder()
        .setColor("Green")
        .setTitle(`Data for Ban ID: ${CurrentBanID}`)
        .setDescription(
          `**__Name:__** \`${BanData.name}\`\n**__Ban Grund:__** \`${BanData.reason}\`\n**__Discord:__** \`${BanData.discord}\`\n**__License:__** \`${BanData.license}\`\n**__Steam:__** \`${BanData.steam}\`\n**__Manual Ban:__** \`${BanData.manual}\``
        )
        .setTimestamp();
      const nextButton = new ButtonBuilder()
        .setStyle(ButtonStyle.Secondary)
        .setLabel("▶")
        .setDisabled(
          CurrentPage == Object.keys(bansjson).length - 1 ? true : false
        )
        .setCustomId(`next`);
      const previousButton = new ButtonBuilder()
        .setStyle(ButtonStyle.Secondary)
        .setLabel("◀")
        .setCustomId("previous")
        .setDisabled(CurrentPage == 0 ? true : false);
      const aR = new ActionRowBuilder().addComponents(
        previousButton,
        nextButton
      );
      await interaction.update({ embeds: [embed], components: [aR] });
      client.UserBanLists.set(interaction.user.id, CurrentPage);
    } else if (customId === "previous") {
      const CurrentPage = page - 1;
      const CurrentBanID = Object.keys(bansjson)[CurrentPage];
      const BanData = bansjson[CurrentBanID];

      const embed = new EmbedBuilder()
        .setColor("Green")
        .setTitle(`Data for Ban ID: ${CurrentBanID}`)
        .setDescription(
          `**Name: \`${BanData.name}\`\nReason: \`${BanData.reason}\`\nManual: \`${BanData.manual}\`\nDiscord: \`${BanData.discord}\`\nLicense: \`${BanData.license}\`\nSteam: \`${BanData.steam}\`**`
        )
        .setTimestamp();

      const nextButton = new ButtonBuilder()
        .setStyle(ButtonStyle.Secondary)
        .setLabel("▶")
        .setCustomId(`next`)
        .setDisabled(
          CurrentPage == Object.keys(bansjson).length - 1 ? true : false
        );

      const previousButton = new ButtonBuilder()
        .setStyle(ButtonStyle.Secondary)
        .setLabel("◀")
        .setCustomId("previous")
        .setDisabled(CurrentPage == 0 ? true : false);

      const aR = new ActionRowBuilder().addComponents(
        previousButton,
        nextButton
      );

      await interaction.update({ embeds: [embed], components: [aR] });

      client.UserBanLists.set(interaction.user.id, CurrentPage);
    }
  },
};
