local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords

function CreateExtendedPlayer(playerId, identifier, group, accounts, inventory, weight, job, loadout, name, coords)
	local targetOverrides = Config.PlayerFunctionOverride and Core.PlayerFunctionOverrides
		[Config.PlayerFunctionOverride] or {}

	local self = {}

	self.accounts = accounts
	self.coords = coords
	self.group = group
	self.identifier = identifier
	self.license = self.identifier
	self.inventory = inventory
	self.job = job
	self.loadout = loadout
	self.name = name
	self.playerId = playerId
	self.source = playerId
	self.variables = {}
	self.weight = weight
	self.admin = Core.IsPlayerAdmin(playerId)

	ExecuteCommand(('add_principal identifier.license:%s group.%s'):format(self.license, self.group))

	local stateBag = Player(self.source).state
	stateBag:set("identifier", self.identifier, true)
	stateBag:set("license", self.license, true)
	stateBag:set("job", self.job, true)
	stateBag:set("group", self.group, true)
	stateBag:set("name", self.name, true)

	function self.triggerEvent(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	function self.setCoords(coordinates)
		local Ped = GetPlayerPed(self.source)
		local vector = type(coordinates) == "vec4" and coordinates or
			type(coordinates) == "vec3" and vec4(coordinates, 0.0) or
			vec(coordinates.x, coordinates.y, coordinates.z, coordinates.heading or 0.0)
		SetEntityCoords(Ped, vector.xyz, false, false, false, false)
		SetEntityHeading(Ped, vector.w)
	end

	function self.getCoords(vector)
		local ped = GetPlayerPed(self.source)
		local coordinates = GetEntityCoords(ped)

		if vector then
			return coordinates
		else
			return {
				x = coordinates.x,
				y = coordinates.y,
				z = coordinates.z,
			}
		end
	end

	function self.kick(reason)
		DropPlayer(self.source, reason)
	end

	function self.setMoney(money)
		money = ESX.Math.Round(money)
		self.setAccountMoney('money', money)
	end

	function self.getMoney()
		return self.getAccount('money').money
	end

	function self.addMoney(money, reason)
		money = ESX.Math.Round(money)
		self.addAccountMoney('money', money, reason)
	end

	function self.removeMoney(money, reason)
		money = ESX.Math.Round(money)
		self.removeAccountMoney('money', money, reason)
	end

	function self.getIdentifier()
		return self.identifier
	end

	function self.setGroup(newGroup)
		ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.license, self.group))
		self.group = newGroup
		Player(self.source).state:set("group", self.group, true)
		ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.license, self.group))

		Wait(2500)
		TriggerClientEvent("group:update", self.source, self.group)
	end

	function self.getGroup()
		return self.group
	end

	function self.set(k, v)
		self.variables[k] = v
		Player(self.source).state:set(k, v, true)
	end

	function self.get(k)
		return self.variables[k]
	end

	function self.getAccounts(minimal)
		if not minimal then
			return self.accounts
		end

		local minimalAccounts = {}

		for i = 1, #self.accounts do
			minimalAccounts[self.accounts[i].name] = self.accounts[i].money
		end

		return minimalAccounts
	end

	function self.getAccount(account)
		for i = 1, #self.accounts do
			if self.accounts[i].name == account then
				return self.accounts[i]
			end
		end
		return nil
	end

	function self.getInventory(minimal)
		if minimal then
			local minimalInventory = {}

			for _, v in next, (self.inventory) do
				if v.count > 0 then
					minimalInventory[v.name] = v.count
				end
			end

			return minimalInventory
		end

		return self.inventory
	end

	function self.getJob()
		return self.job
	end

	function self.getLoadout(minimal)
		if not minimal then
			return self.loadout
		end
		local minimalLoadout = {}

		for _, v in next, (self.loadout) do
			minimalLoadout[v.name] = { ammo = v.ammo }
			if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

			if #v.components > 0 then
				local components = {}

				for _, component in next, (v.components) do
					if component ~= 'clip_default' then
						components[#components + 1] = component
					end
				end

				if #components > 0 then
					minimalLoadout[v.name].components = components
				end
			end
		end

		return minimalLoadout
	end

	function self.getName()
		return self.name
	end

	function self.setName(newName)
		self.name = newName
		Player(self.source).state:set("name", self.name, true)
	end

	function self.setAccountMoney(accountName, money, reason)
		reason = reason or 'unknown'
		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				money = account.round and ESX.Math.Round(money) or money
				self.accounts[account.index].money = money

				self.triggerEvent('esx:setAccountMoney', account, "set", money)
				TriggerEvent('esx:setAccountMoney', self.source, accountName, money, reason)
			end
		end
	end

	function self.addAccountMoney(accountName, money, reason)
		reason = reason or 'Unknown'
		if money > 0 then
			local account = self.getAccount(accountName)
			if account then
				money = account.round and ESX.Math.Round(money) or money
				self.accounts[account.index].money = self.accounts[account.index].money + money

				self.triggerEvent('esx:setAccountMoney', account, "add", money)
				TriggerEvent('esx:addAccountMoney', self.source, accountName, money, reason)
			end
		end
	end

	function self.removeAccountMoney(accountName, money, reason)
		reason = reason or 'Unknown'
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				money = account.round and ESX.Math.Round(money) or money
				self.accounts[account.index].money = self.accounts[account.index].money - money

				self.triggerEvent('esx:setAccountMoney', account, "remove", money)
				TriggerEvent('esx:removeAccountMoney', self.source, accountName, money, reason)
			end
		end
	end

	function self.getInventoryItem(itemName)
		for _, v in next, (self.inventory) do
			if v.name == itemName then
				return v
			end
		end
	end

	function self.addInventoryItem(itemName, count)
		local item = self.getInventoryItem(itemName)

		if item then
			count = ESX.Math.Round(count)
			item.count = item.count + count
			self.weight = self.weight + (item.weight * count)

			TriggerEvent('esx:onAddInventoryItem', self.source, item.name, item.count)
			self.triggerEvent('esx:addInventoryItem', item.name, item.count)
		end
	end

	function self.removeInventoryItem(itemName, count)
		local item = self.getInventoryItem(itemName)

		if item then
			count = ESX.Math.Round(count)
			if count > 0 then
				local newCount = item.count - count

				if newCount >= 0 then
					item.count = newCount
					self.weight = self.weight - (item.weight * count)

					TriggerEvent('esx:onRemoveInventoryItem', self.source, item.name, item.count)
					self.triggerEvent('esx:removeInventoryItem', item.name, item.count)
				end
			end
		end
	end

	function self.setInventoryItem(itemName, count)
		local item = self.getInventoryItem(itemName)

		if item and count >= 0 then
			count = ESX.Math.Round(count)

			if count > item.count then
				self.addInventoryItem(item.name, count - item.count)
			else
				self.removeInventoryItem(item.name, item.count - count)
			end
		end
	end

	function self.getWeight()
		return self.weight
	end

	function self.getMaxWeight()
		return self.maxWeight
	end

	function self.canCarryItem(itemName, count)
		if ESX.Items[itemName] then
			local currentWeight, itemWeight = self.weight, ESX.Items[itemName].weight
			local newWeight = currentWeight + (itemWeight * count)

			return newWeight <= self.maxWeight
		end
	end

	function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
		local firstItemObject = self.getInventoryItem(firstItem)
		local testItemObject = self.getInventoryItem(testItem)

		if firstItemObject.count >= firstItemCount then
			local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
			local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

			return weightWithTestItem <= self.maxWeight
		end

		return false
	end

	function self.setMaxWeight(newWeight)
		self.maxWeight = newWeight
		self.triggerEvent('esx:setMaxWeight', self.maxWeight)
	end

	function self.setJob(newJob, grade)
		grade = tostring(grade)
		local lastJob = json.decode(json.encode(self.job))

		if ESX.DoesJobExist(newJob, grade) then
			local jobObject, gradeObject = ESX.Jobs[newJob], ESX.Jobs[newJob].grades[grade]

			self.job.id                  = jobObject.id
			self.job.name                = jobObject.name
			self.job.label               = jobObject.label

			self.job.grade               = tonumber(grade)
			self.job.grade_name          = gradeObject.name
			self.job.grade_label         = gradeObject.label
			self.job.grade_salary        = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end

			TriggerEvent('esx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('esx:setJob', self.job, lastJob)
			Player(self.source).state:set("job", self.job, true)
			MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @job_grade WHERE identifier = @identifier', { ['@identifier'] = self.identifier, ['@job'] = newJob, ['@job_grade'] = grade })
		end
	end

	function self.addWeapon(weaponName, ammo)
		if not self.hasWeapon(weaponName) then
			local weaponLabel = ESX.GetWeaponLabel(weaponName)

			table.insert(self.loadout, {
				name = weaponName,
				ammo = ammo,
				label = weaponLabel,
				components = {},
				tintIndex = 0
			})

			GiveWeaponToPed(GetPlayerPed(self.source), joaat(weaponName), ammo, false, false)
			self.triggerEvent('esx:addInventoryItem', weaponLabel, false, true)
		end
	end

	function self.addWeaponComponent(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if not self.hasWeaponComponent(weaponName, weaponComponent) then
					self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
					local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash
					GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
					self.triggerEvent('esx:addInventoryItem', component.label, false, true)
				end
			end
		end
	end

	function self.addWeaponAmmo(weaponName, ammoCount)
		local _, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo + ammoCount
			SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
		end
	end

	function self.updateWeaponAmmo(weaponName, ammoCount)
		local _, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = ammoCount
		end
	end

	function self.setWeaponTint(weaponName, weaponTintIndex)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local _, weaponObject = ESX.GetWeapon(weaponName)
			if weaponObject.tints and weaponObject.tints[tonumber(weaponTintIndex)] then
				self.loadout[loadoutNum].tintIndex = tonumber(weaponTintIndex)
				self.triggerEvent('esx:setWeaponTint', weaponName, tonumber(weaponTintIndex))
			end
		end
	end

	function self.getWeaponTint(weaponName)
		local _, weapon = self.getWeapon(weaponName)

		if weapon then
			return weapon.tintIndex
		end

		return 0
	end

	function self.removeWeapon(weaponName)
		local weaponLabel, playerPed = nil, GetPlayerPed(self.source)

		for k, v in next, (self.loadout) do
			if v.name == weaponName then
				weaponLabel = v.label

				for _, v2 in next, (v.components) do
					self.removeWeaponComponent(weaponName, v2)
				end

				local weaponHash = joaat(v.name)

				RemoveWeaponFromPed(playerPed, weaponHash)
				SetPedAmmo(playerPed, weaponHash, 0)

				table.remove(self.loadout, k)
				break
			end
		end

		if weaponLabel then
			self.triggerEvent('esx:removeInventoryItem', weaponLabel, false, true)
		end
	end

	function self.removeWeaponComponent(weaponName, weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if self.hasWeaponComponent(weaponName, weaponComponent) then
					for k, v in next, (self.loadout[loadoutNum].components) do
						if v == weaponComponent then
							table.remove(self.loadout[loadoutNum].components, k)
							break
						end
					end

					self.triggerEvent('esx:removeWeaponComponent', weaponName, weaponComponent)
					self.triggerEvent('esx:removeInventoryItem', component.label, false, true)
				end
			end
		end
	end

	function self.removeWeaponAmmo(weaponName, ammoCount)
		local _, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo - ammoCount
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	function self.hasWeaponComponent(weaponName, weaponComponent)
		local _, weapon = self.getWeapon(weaponName)

		if weapon then
			for _, v in next, (weapon.components) do
				if v == weaponComponent then
					return true
				end
			end

			return false
		else
			return false
		end
	end

	function self.hasWeapon(weaponName)
		for _, v in next, (self.loadout) do
			if v.name == weaponName then
				return true
			end
		end

		return false
	end

	function self.hasItem(item)
		for _, v in next, (self.inventory) do
			if (v.name == item) and (v.count >= 1) then
				return v, v.count
			end
		end

		return false
	end

	function self.getWeapon(weaponName)
		for k, v in next, (self.loadout) do
			if v.name == weaponName then
				return k, v
			end
		end
	end

	function self.showAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
		self.triggerEvent('esx:showAdvancedNotification', sender, subject, msg, textureDict, iconType, flash, saveToBrief,
			hudColorIndex)
	end

	function self.showHelpNotification(msg, thisFrame, beep, duration)
		self.triggerEvent('esx:showHelpNotification', msg, thisFrame, beep, duration)
	end

	for fnName, fn in next, (targetOverrides) do
		self[fnName] = fn(self)
	end

	return self
end
