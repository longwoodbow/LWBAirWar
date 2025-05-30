// Plane logic

#include "PlaneCommon.as";
#include "Hitters.as";
#include "StandardControlsCommon.as"

bool zoomModifier = false; // decides whether to use the 3 zoom system or not
int zoomModifierLevel = 4; // for the extra zoom levels when pressing the modifier key
int zoomLevel = 4; // we can declare a global because this script is just used by myPlayer

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false;
	this.set_s32("tap_time", getGameTime());

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	PlaneInfo plane;
	this.set("planeInfo", @plane);

	this.set_f32("gib health", -1.5f);
	this.Tag("player");
	this.Tag("landed");
	this.Tag("spawned");

	this.set_f32("explosive_radius", 64.0f);
	this.set_f32("explosive_damage", 0.0f);
	this.set_f32("map_damage_radius", 64.0f);
	this.set_f32("map_damage_ratio", 0.1f);
	this.set_bool("map_damage_raycast", true);
	this.Tag("exploding");

	this.set("target0", null);
	this.set("target1", null);
	this.set("target2", null);
	this.set("target3", null);
	this.set("target_GRKT", null);

	this.getShape().SetRotationsAllowed(true);
	this.getShape().getConsts().net_threshold_multiplier = 0.5f;

	this.addCommandID("shoot bullet");
	this.addCommandID("shoot bullet client");
	this.addCommandID("shoot missile");
	this.addCommandID("shoot missile client");
	this.addCommandID("shoot special");
	this.addCommandID("shoot special client");
	this.addCommandID("shoot flare");
	this.addCommandID("shoot flare client");
	this.addCommandID("landing");
	this.addCommandID("landing client");
	this.addCommandID("take off");
	this.addCommandID("take off client");
	//this.addCommandID("change special");
	//this.addCommandID("change special client");

	this.set_u16("GRKT", 0);
	this.set_u16("TLS", 0);
	this.set_u16("IEWS", 0);

	//dont collide with top of the map
	this.SetMapEdgeFlags(CBlob::map_collide_none);

	//this.Tag("60fps_camera"); // from StandaedControls.as

	//this.getSprite.SetFrame(5 + XORRandom(5));

	this.getSprite().RemoveSpriteLayer("TLS");
	CSpriteLayer@ tls = this.getSprite().addSpriteLayer("TLS", "TLS.png" , 32, 8, this.getTeamNum(), 0);

	if (tls !is null)
	{
		Animation@ anim = tls.addAnimation("default", 0, false);
		anim.AddFrame(0);
		tls.SetAnimation("default");
		tls.SetRelativeZ(-1.5f);
		tls.SetVisible(false);
	}

	this.getCurrentScript().removeIfTag = "dead";
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		player.SetScoreboardVars("ScoreboardIcons.png", 3, Vec2f(16, 16));
	}
}

void onTick(CBlob@ this)
{
	this.Untag("ECM");
	this.Untag("ESM");

	// it dies when leaving the map
	{
		Vec2f pos = this.getPosition();
		if (
			pos.x < 0.1f ||
			pos.x > (getMap().tilemapwidth * getMap().tilesize) - 0.1f ||
			pos.y < 0.1f ||
			pos.y > (getMap().tilemapheight * getMap().tilesize) - 0.1f
		) {
			this.server_Die();
			return;
		}
	}

	if (this.isMyPlayer())
	{
		ManageCamera(this);

		if (this.isKeyJustPressed(key_action1))
		{
			CGridMenu @gmenu;
			CGridButton @gbutton;
		
			this.ClickGridMenu(0, gmenu, gbutton);
		}

		if (this.hasTag("spawned")) // want to do it in onInit...
		{
			MakeSpecialWeaponMenu(this);
			this.Untag("spawned");
		}
	}

	PlaneInfo@ plane;
	if (!this.get("planeInfo", @plane))
	{
		return;
	}

	if (this.isInInventory())
	{
		return;
	}

	if (this.hasTag("landed"))
	{
		this.server_SetHealth(this.getHealth()); // heal

		this.setVelocity(Vec2f_zero); // stop moving

		plane.bullet_time = 0;
		plane.missile_time_0 = 0;
		plane.missile_time_1 = 0;
		plane.special_time_0 = 0;
		plane.special_time_1 = 0;
		plane.special_time_2 = 0;
		plane.special_time_3 = 0;

		plane.amount_missile = 16;
		plane.amount_flare = 4;
		plane.amount_special = specialAmounts[plane.special_type];

		// click menu
		if (this.isMyPlayer()) 
		{
			if (this.isKeyJustPressed(key_use)) 
			{
				this.SendCommand(this.getCommandID("take off"));
				this.ClearMenus();
			}
		}
		return;
	}

	// cooldown
	if (plane.bullet_time > 0) plane.bullet_time--;
	if (plane.missile_time_0 > 0 &&
		(plane.amount_missile >= 2 || // always reload if amount >= 2
			(plane.amount_missile >= 1 && plane.missile_time_1 >= missile_cooldown) // when amount == 1, reload if another side is not reloading
			)) plane.missile_time_0--;
	if (plane.missile_time_1 > 0 &&
		(plane.amount_missile >= 2 ||
			(plane.amount_missile >= 1 && plane.missile_time_0 >= missile_cooldown)
			)) plane.missile_time_1--;

	u16 specialCooldown = specialCooldowns[plane.special_type];
	if (specialCharges[plane.special_type] == 1)
	{
		if (plane.special_time_0 > 0 && plane.amount_special >= 1) plane.special_time_0--;
		if (plane.special_time_2 > 0) plane.special_time_2--; // do it for mgp and plsl
	}
	else if (specialCharges[plane.special_type] == 2)
	{
		if (plane.special_time_0 > 0 && 
			(plane.amount_special >= 2 ||
				(plane.amount_special >= 1 && plane.special_time_1 >= specialCooldown)
				)) plane.special_time_0--;
		if (plane.special_time_1 > 0 && 
			(plane.amount_special >= 2 ||
				(plane.amount_special >= 1 && plane.special_time_0 >= specialCooldown)
				)) plane.special_time_1--;
		if (plane.special_time_2 > 0) plane.special_time_2--; // do it for mgp and plsl
	}
	else if (specialCharges[plane.special_type] == 4) // wish that there are better ways
	{
		if (plane.special_time_0 > 0 && 
			(plane.amount_special >= 4 || // >= 4
				// == 3, 1 slot is not loading
				(plane.amount_special >= 3 && (plane.special_time_1 >= specialCooldown || plane.special_time_2 >= specialCooldown || plane.special_time_3 >= specialCooldown)) ||
				// == 2, it's the worst, 2 slots are not loading
				(plane.amount_special >= 2 && ((plane.special_time_1 >= specialCooldown && plane.special_time_2 >= specialCooldown) || (plane.special_time_1 >= specialCooldown && plane.special_time_3 >= specialCooldown) || (plane.special_time_2 >= specialCooldown && plane.special_time_3 >= specialCooldown))) ||
				// == 1, 3 slots are not loading
				(plane.amount_special >= 1 && plane.special_time_1 >= specialCooldown && plane.special_time_2 >= specialCooldown && plane.special_time_3 >= specialCooldown)
				)) plane.special_time_0--;
		if (plane.special_time_1 > 0 && 
			(plane.amount_special >= 4 || // >= 4
				// == 3
				(plane.amount_special >= 3 && (plane.special_time_0 >= specialCooldown || plane.special_time_2 >= specialCooldown || plane.special_time_3 >= specialCooldown)) ||
				// == 2, it's the worst
				(plane.amount_special >= 2 && ((plane.special_time_0 >= specialCooldown && plane.special_time_2 >= specialCooldown) || (plane.special_time_0 >= specialCooldown && plane.special_time_3 >= specialCooldown) || (plane.special_time_2 >= specialCooldown && plane.special_time_3 >= specialCooldown))) ||
				// == 1
				(plane.amount_special >= 1 && plane.special_time_0 >= specialCooldown && plane.special_time_2 >= specialCooldown && plane.special_time_3 >= specialCooldown)
				)) plane.special_time_1--;
		if (plane.special_time_2 > 0 && 
			(plane.amount_special >= 4 || // >= 4
				// == 3
				(plane.amount_special >= 3 && (plane.special_time_1 >= specialCooldown || plane.special_time_0 >= specialCooldown || plane.special_time_3 >= specialCooldown)) ||
				// == 2, it's the worst
				(plane.amount_special >= 2 && ((plane.special_time_1 >= specialCooldown && plane.special_time_0 >= specialCooldown) || (plane.special_time_1 >= specialCooldown && plane.special_time_3 >= specialCooldown) || (plane.special_time_0 >= specialCooldown && plane.special_time_3 >= specialCooldown))) ||
				// == 1
				(plane.amount_special >= 1 && plane.special_time_1 >= specialCooldown && plane.special_time_0 >= specialCooldown && plane.special_time_3 >= specialCooldown)
				)) plane.special_time_2--;
		if (plane.special_time_3 > 0 && 
			(plane.amount_special >= 4 || // >= 4
				// == 3
				(plane.amount_special >= 3 && (plane.special_time_1 >= specialCooldown || plane.special_time_2 >= specialCooldown || plane.special_time_0 >= specialCooldown)) ||
				// == 2, it's the worst
				(plane.amount_special >= 2 && ((plane.special_time_1 >= specialCooldown && plane.special_time_2 >= specialCooldown) || (plane.special_time_1 >= specialCooldown && plane.special_time_0 >= specialCooldown) || (plane.special_time_2 >= specialCooldown && plane.special_time_0 >= specialCooldown))) ||
				// == 1
				(plane.amount_special >= 1 && plane.special_time_1 >= specialCooldown && plane.special_time_2 >= specialCooldown && plane.special_time_0 >= specialCooldown)
				)) plane.special_time_3--;
	}

	// operate special weapons
	CMap@ map = getMap();

	if (this.get_u16("GRKT") > 0)
	{
		if (this.get_u16("GRKT") % 8 == 1)
		{
			if (isServer())
			{
				CBlob@ missile = server_CreateBlobNoInit("grkt");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target", this.get_netid("target_GRKT"));
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition());
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees() + (10.0f - XORRandom(256) / 255.0f * 20.0f))) * this.getVelocity().getLength());
	
				}
			}
			if (isClient())
			{
				Sound::Play("ProduceSound.ogg", this.getPosition());
			}
		}

		this.sub_u16("GRKT", 1);
	}
	if (this.get_u16("TLS") > 0)
	{
		// operate ray
		HitInfo@[] rayInfos;
		map.getHitInfosFromRay(this.getPosition(), this.getAngleDegrees() - 90.0f, 750.0f, this, rayInfos);
		f32 finalHit = 750.0f;

		for (int i = 0; i < rayInfos.size(); i++)
		{
			CBlob@ rayb = rayInfos[i].blob;
			
			if (rayb is null) // map hit
			{
				finalHit = (rayInfos[i].hitpos - this.getPosition()).getLength();
				break;
			}

			if (rayb.hasTag("projectile") || rayb.getTeamNum() == this.getTeamNum()) continue;
		
			if (isServer() && this.get_u16("TLS") % 3 == 0)
			{
				this.server_Hit(rayb, this.getPosition(), this.getVelocity(), 1.0f, Hitters::arrow);
			}

			bool large = rayb.getName() == "airwar_base"; // usually doors, but can also be boats/some mechanisms

			if (large)
			{
				finalHit = (rayInfos[i].hitpos - this.getPosition()).getLength();
				break; // don't raycast past the door after we do damage to it
			}
		}
		
		//effect check
		if (isClient())
		{
			CSpriteLayer@ tls = this.getSprite().getSpriteLayer("TLS");
			if (tls !is null)
			{
				f32 laserlen = Maths::Max(0.1f, finalHit / 32.0f);

				tls.ResetTransform();
				tls.ScaleBy(Vec2f(laserlen, 1.0f));

				tls.TranslateBy(Vec2f(laserlen * 16.0f, 0.0f));

				tls.RotateBy(-90.0f, Vec2f());

				tls.SetVisible(true);
			}
		}
		this.sub_u16("TLS", 1);
	}
	else
	{
		CSpriteLayer@ tls = this.getSprite().getSpriteLayer("TLS");
		if (tls !is null)
		{
			tls.SetVisible(false);
		}
	}
	if (this.get_u16("IEWS") > 0) this.sub_u16("IEWS", 1); // IEWS is operated by reciever, so don't need to do anything

	// control

	// accel
	if (this.isKeyPressed(key_up) && !this.isKeyPressed(key_down))
	{
		this.AddForce(Vec2f(0.0f, -100.0f).RotateBy(this.getAngleDegrees()));
	}
	// brake
	else if (this.isKeyPressed(key_down) && !this.isKeyPressed(key_up))
	{
		this.AddForce(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));
	}
	// standard speed
	else
	{
		this.AddForce(Vec2f(0.0f, -50.0f).RotateBy(this.getAngleDegrees()));
	}

	// yaw
	if (this.isKeyPressed(key_left) && !this.isKeyPressed(key_right))
	{
		this.setAngleDegrees(this.getAngleDegrees() - 2.0f);
		this.setVelocity(this.getVelocity().RotateBy(-2.0f));
	}
	else if (this.isKeyPressed(key_right) && !this.isKeyPressed(key_left))
	{
		this.setAngleDegrees(this.getAngleDegrees() + 2.0f);
		this.setVelocity(this.getVelocity().RotateBy(2.0f));
	}

	// check ECM and ESM
	// need only on client side
	CBlob@[] planes;
	if (map.getBlobsInRadius(this.getPosition(), 500.0f, @planes))
	{
		for (int i = 0; i < planes.size(); i++)
		{
			CBlob@ plane = planes[i];
			if (plane.getName() == "plane" && plane.get_u16("IEWS") > 0)
			{
				if (plane.getTeamNum() == this.getTeamNum()) this.Tag("ESM");
				else this.Tag("ECM");
			}
		}
	}

	if (!this.isMyPlayer()) return;

	if (this.isKeyJustPressed(key_use) && !this.hasTag("landed"))
	{
		CBlob@[] overlapping;
		if (this.getOverlapping(@overlapping))
		{
			for(int i = 0; i < overlapping.size(); i++)
			{
				CBlob@ b = overlapping[i];
				if (b.getName() == "airwar_base" && this.getTeamNum() == b.getTeamNum())
				{
					this.SendCommand(this.getCommandID("landing"));

					MakeSpecialWeaponMenu(this);

					break;
				}
			}
		}
	}

	// active/deactive special weapon
	if (this.isKeyJustPressed(key_inventory))
	{
		plane.use_special = !plane.use_special;
		Sound::Play("/CycleInventory.ogg");
	}

	// radar
	u16 radarRange = plane.use_special ? specialRanges[plane.special_type] : missile_range;
	u16 radarArc = plane.use_special ? specialArcs[plane.special_type] : missile_arc;
	u8 target = 255;
	u8 target1 = 255;
	u8 target2 = 255;
	u8 target3 = 255;
	CBlob@ targetBlob = null;
	this.get("target0", @targetBlob);
	CBlob@ targetBlob1 = null;
	this.get("target1", @targetBlob1);
	CBlob@ targetBlob2 = null;
	this.get("target2", @targetBlob2);
	CBlob@ targetBlob3 = null;
	this.get("target3", @targetBlob3);
	HitInfo@[] hitInfos;
	CBlob@[] targetInfos;
	// getHitInfosFromArc with long distance has an issue...
	// I guess it has better scripting
	bool mstm = plane.use_special && plane.special_type == SpecialWeaponType::mstm;
	if (radarRange > 0 && map.getHitInfosFromArc(this.getPosition(), this.getAngleDegrees() - 90.0f, 360, this.getRadius() + radarRange, this, @hitInfos))
	{
		for (int i = 0; i < hitInfos.size(); i++)
		{
			CBlob@ b = hitInfos[i].blob;
			if (b !is null && (  
				(b.hasTag("player") && (!plane.use_special || plane.special_type < SpecialWeaponType::lagm || plane.special_type > SpecialWeaponType::grkt)) || // air
				(b.getName() == "airwar_base" && (!plane.use_special || plane.special_type > SpecialWeaponType::sasm)) // ground
				) && 
			this.getTeamNum() != b.getTeamNum() && !b.hasTag("landed"))
			{
				float angle = (b.getPosition() - this.getPosition()).getAngle() + this.getAngleDegrees() - 90.0f;
				while (angle > 180.0f)
				{
					angle -= 360.0f;
				}

				while (angle < -180.0f)
				{
					angle += 360.0f;
				}

				if (angle >= -(radarArc / 2) && angle <= radarArc /2)
				{
					targetInfos.push_back(b);

					if (b is targetBlob)
					{
						target = i;
						this.set("target0", @b);
					}
					else if (b is targetBlob1)
					{
						target1 = i;
						this.set("target1", @b);
					}
					else if (b is targetBlob2)
					{
						target2 = i;
						this.set("target1", @b);
					}
					else if (b is targetBlob3)
					{
						target3 = i;
						this.set("target1", @b);
					}
				}
			}
		}

		if (target == 255)
		{
			this.set("target0", null);
		}
		if (target1 == 255)
		{
			this.set("target1", null);
		}
		if (target2 == 255)
		{
			this.set("target2", null);
		}
		if (target3 == 255)
		{
			this.set("target3", null);
		}

		if (mstm)
		{
			for (int i = 0; i < targetInfos.size(); i++)
			{
				CBlob@ b = targetInfos[i];
				CBlob@ blob0;
				this.get("target0", @blob0);
				CBlob@ blob1;
				this.get("target1", @blob1);
				CBlob@ blob2;
				this.get("target2", @blob2);
				CBlob@ blob3;
				this.get("target3", @blob3);

				if (blob0 is null && b !is blob1 && b !is blob2 && b !is blob3)
				{
					this.set("target0", @b);
				}
				else if (blob1 is null && b !is blob0 && b !is blob2 && b !is blob3)
				{
					this.set("target1", @b);
				}
				else if (blob2 is null && b !is blob1 && b !is blob0 && b !is blob3)
				{
					this.set("target2", @b);
				}
				else if (blob3 is null && b !is blob1 && b !is blob2 && b !is blob0)
				{
					this.set("target3", @b);
				}
			}
		}
		else
		{
			this.set("target1", null);
			this.set("target2", null);
			this.set("target3", null);
			if (targetBlob is null && targetInfos.length >= 1)
			{
				this.set("target0", @targetInfos[0]);
			}
			// change target
			else if (this.isKeyJustPressed(key_pickup))
			{
				u8 nextTarget = target + 1;
				if (nextTarget < targetInfos.length())
				{
					target = nextTarget;
				}
				else
				{
					target = 0;
				}

				this.set("target0", @targetInfos[target]);
			}
		}
	}
	else
	{
		this.set("target0", null);
		this.set("target1", null);
		this.set("target2", null);
		this.set("target3", null);
	}

	// shoot bullet
	if (this.isKeyPressed(key_action1) && plane.bullet_time == 0)
	{
		plane.bullet_time = bullet_cooldown;
		this.SendCommand(this.getCommandID("shoot bullet"));
	}

	// shoot missile/special weapon
	// PLSL and MGP are auto
	if (plane.use_special && (plane.special_type == SpecialWeaponType::mgp || plane.special_type == SpecialWeaponType::plsl))
	{
		// use special 2 as delay
		if (this.isKeyPressed(key_action2) && plane.special_time_2 == 0)
		{
			if (specialCharges[plane.special_type] > 0 && plane.special_time_0 == 0)
			{
				plane.amount_special--;
				plane.special_time_0 = specialCooldowns[plane.special_type];

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(0);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(0xFFFF);

				this.SendCommand(this.getCommandID("shoot special"), params);
				if (plane.special_type == SpecialWeaponType::mgp) plane.special_time_2 = 3;
				else plane.special_time_2 = 13;
			}
			else if (specialCharges[plane.special_type] > 1 && plane.special_time_1 == 0)
			{
				plane.amount_special--;
				plane.special_time_1 = specialCooldowns[plane.special_type];

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(1);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(0xFFFF);

				this.SendCommand(this.getCommandID("shoot special"), params);

				plane.special_time_2 = 13;
			}
		}
	}
	else if (this.isKeyJustPressed(key_action2))
	{
		CBlob@ targetBlob = null;
		this.get("target0", @targetBlob);
		CBlob@ targetBlob1 = null;
		this.get("target1", @targetBlob1);
		CBlob@ targetBlob2 = null;
		this.get("target2", @targetBlob2);
		CBlob@ targetBlob3 = null;
		this.get("target3", @targetBlob3);

		if (plane.use_special == false)
		{
			if (plane.missile_time_0 == 0)
			{
				plane.amount_missile--;
				plane.missile_time_0 = missile_cooldown;

				CBitStream params;
				params.write_u8(0);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(targetBlob is null ? 0xFFFF : targetBlob.getNetworkID());

				this.SendCommand(this.getCommandID("shoot missile"), params);
			}
			else if (plane.missile_time_1 == 0)
			{
				plane.amount_missile--;
				plane.missile_time_1 = missile_cooldown;

				CBitStream params;
				params.write_u8(1);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(targetBlob is null ? 0xFFFF : targetBlob.getNetworkID());

				this.SendCommand(this.getCommandID("shoot missile"), params);
			}
		}
		else if (plane.use_special && plane.special_type == SpecialWeaponType::mstm)
		{
			bool shot0 = false;
			bool shot1 = false;
			bool shot2 = false;
			bool shot3 = false;

			bool shotMSTM0 = false;
			if (plane.special_time_0 == 0)
			{
				plane.amount_special--;
				plane.special_time_0 = specialCooldowns[plane.special_type];

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(0);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				CBlob@ target = null;
				if (targetBlob !is null && !shot0)
				{
					@target = @targetBlob;
					shot0 = true;
				}
				else if (targetBlob1 !is null && !shot1)
				{
					@target = @targetBlob1;
					shot1 = true;
				}
				else if (targetBlob2 !is null && !shot2)
				{
					@target = @targetBlob2;
					shot2 = true;
				}
				else if (targetBlob3 !is null && !shot3)
				{
					@target = @targetBlob3;
					shot3 = true;
				}

				params.write_netid(target is null ? 0xFFFF : target.getNetworkID());
				shotMSTM0 = true;

				this.SendCommand(this.getCommandID("shoot special"), params);
			}
			if (plane.special_time_1 == 0)
			{

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(1);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				CBlob@ target = null;
				if (targetBlob !is null && !shot0)
				{
					@target = @targetBlob;
					shot0 = true;
				}
				else if (targetBlob1 !is null && !shot1)
				{
					@target = @targetBlob1;
					shot1 = true;
				}
				else if (targetBlob2 !is null && !shot2)
				{
					@target = @targetBlob2;
					shot2 = true;
				}
				else if (targetBlob3 !is null && !shot3)
				{
					@target = @targetBlob3;
					shot3 = true;
				}

				params.write_netid(target is null ? 0xFFFF : target.getNetworkID());
				if (target !is null || !shotMSTM0)
				{
					shotMSTM0 = true;
					this.SendCommand(this.getCommandID("shoot special"), params);
					plane.amount_special--;
					plane.special_time_1 = specialCooldowns[plane.special_type];
				}
			}
			if (plane.special_time_2 == 0)
			{

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(2);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				CBlob@ target = null;
				if (targetBlob !is null && !shot0)
				{
					@target = @targetBlob;
					shot0 = true;
				}
				else if (targetBlob1 !is null && !shot1)
				{
					@target = @targetBlob1;
					shot1 = true;
				}
				else if (targetBlob2 !is null && !shot2)
				{
					@target = @targetBlob2;
					shot2 = true;
				}
				else if (targetBlob3 !is null && !shot3)
				{
					@target = @targetBlob3;
					shot3 = true;
				}

				params.write_netid(target is null ? 0xFFFF : target.getNetworkID());
				if (target !is null || !shotMSTM0)
				{
					shotMSTM0 = true;
					this.SendCommand(this.getCommandID("shoot special"), params);
					plane.amount_special--;
					plane.special_time_2 = specialCooldowns[plane.special_type];
				}
			}
			if (plane.special_time_3 == 0)
			{
				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(3);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				CBlob@ target = null;
				if (targetBlob !is null && !shot0)
				{
					@target = @targetBlob;
					shot0 = true;
				}
				else if (targetBlob1 !is null && !shot1)
				{
					@target = @targetBlob1;
					shot1 = true;
				}
				else if (targetBlob2 !is null && !shot2)
				{
					@target = @targetBlob2;
					shot2 = true;
				}
				else if (targetBlob3 !is null && !shot3)
				{
					@target = @targetBlob3;
					shot3 = true;
				}

				params.write_netid(target is null ? 0xFFFF : target.getNetworkID());
				if (target !is null || !shotMSTM0)
				{
					shotMSTM0 = true;
					this.SendCommand(this.getCommandID("shoot special"), params);
					plane.amount_special--;
					plane.special_time_3 = specialCooldowns[plane.special_type];
				}
			}
		}
		else
		{
			if (specialCharges[plane.special_type] > 0 && plane.special_time_0 == 0)
			{
				plane.amount_special--;
				plane.special_time_0 = specialCooldowns[plane.special_type];

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(0);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(targetBlob is null ? 0xFFFF : targetBlob.getNetworkID());

				this.SendCommand(this.getCommandID("shoot special"), params);
			}
			else if (specialCharges[plane.special_type] > 1 && plane.special_time_1 == 0)
			{
				plane.amount_special--;
				plane.special_time_1 = specialCooldowns[plane.special_type];

				CBitStream params;
				params.write_u8(plane.special_type);
				params.write_u8(1);
				params.write_bool(this.hasTag("ECM"));
				params.write_bool(this.hasTag("ESM"));
				params.write_netid(targetBlob is null ? 0xFFFF : targetBlob.getNetworkID());

				this.SendCommand(this.getCommandID("shoot special"), params);
			}
		}
	}

	// flare
	if (this.isKeyJustPressed(key_action3) && plane.amount_flare > 0)
	{	
		this.SendCommand(this.getCommandID("shoot flare"));

		plane.amount_flare--;
	}
}

void MakeSpecialWeaponMenu(CBlob@ this)
{
	CGridMenu@ menu = CreateGridMenu(Vec2f(getScreenWidth() / 2, getScreenHeight() / 2), this, Vec2f(16.0f, 9.0f), "Change Special Weapon");
	if (menu !is null)
	{
		menu.deleteAfterClick = false;

		for (uint i = 0 ; i < SpecialWeaponType::count; i++)
		{
			CBitStream params;
			params.write_u8(i);

			CGridButton@ button = menu.AddTextButton(specialDescriptions[i], "PlaneLogic.as", "Callback_ChangeSpecial", Vec2f(8.0f, 1.0f), params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	// fight
	if (cmd == this.getCommandID("shoot bullet") && isServer())
	{
		CBlob@ bullet = server_CreateBlobNoInit("bullet");
		if (bullet !is null)
		{
			bullet.SetDamageOwnerPlayer(this.getPlayer());
			bullet.Init();
		
			bullet.IgnoreCollisionWhileOverlapped(this);
			bullet.server_setTeamNum(this.getTeamNum());
			bullet.setPosition(this.getPosition());
			bullet.setVelocity(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));

			this.SendCommand(this.getCommandID("shoot bullet client"));
		}
	}
	else if (cmd == this.getCommandID("shoot bullet client") && isClient())
	{
		Sound::Play("M16Fire.ogg", this.getPosition());
	}
	if (cmd == this.getCommandID("shoot missile") && isServer())
	{
		// check ECM and ESM
		bool ecm = false; // from enemy
		bool esm = false; // from ally

		u8 number;
		if (!params.saferead_u8(number)) number = 0;
		params.saferead_bool(ecm);
		params.saferead_bool(esm);
		u16 targetID;
		if (!params.saferead_netid(targetID)) targetID = 0xFFFF;

		CBlob@ missile = server_CreateBlobNoInit("missile");
		if (missile !is null)
		{
			missile.SetDamageOwnerPlayer(this.getPlayer());
			missile.set_netid("target" ,targetID);
			missile.Init();
		
			if (ecm) missile.Tag("ECM");
			if (esm) missile.Tag("ESM");
			missile.IgnoreCollisionWhileOverlapped(this);
			missile.server_setTeamNum(this.getTeamNum());
			missile.setPosition(this.getPosition() + (Vec2f(4.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
			missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());

			this.SendCommand(this.getCommandID("shoot missile client"));
		}
	}
	else if (cmd == this.getCommandID("shoot missile client") && isClient())
	{
		Sound::Play("ProduceSound.ogg", this.getPosition());
	}
	else if (cmd == this.getCommandID("shoot special") && isServer())
	{
		// check ECM and ESM
		bool ecm = false; // from enemy
		bool esm = false; // from ally

		u8 type;
		if (!params.saferead_u8(type)) return;
		u8 number;
		if (!params.saferead_u8(number)) number = 0;
		params.saferead_bool(ecm);
		params.saferead_bool(esm);
		u16 targetID;
		if (!params.saferead_netid(targetID)) targetID = 0xFFFF;

		switch (type)
		{
			case SpecialWeaponType::hcaa:
			{
				CBlob@ missile = server_CreateBlobNoInit("hcaa");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::hpaa:
			{
				CBlob@ missile = server_CreateBlobNoInit("hpaa");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::hvaa:
			{
				CBlob@ missile = server_CreateBlobNoInit("hvaa");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::laam:
			{
				CBlob@ missile = server_CreateBlobNoInit("laam");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::qaam:
			{
				CBlob@ missile = server_CreateBlobNoInit("qaam");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::saam:
			{
				CBlob@ missile = server_CreateBlobNoInit("saam");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.set_netid("owner" ,this.getNetworkID());
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::sasm:
			{
				CBlob@ missile = server_CreateBlobNoInit("sasm");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::lagm:
			{
				CBlob@ missile = server_CreateBlobNoInit("lagm");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::gpb:
			{
				CBlob@ missile = server_CreateBlobNoInit("gpb");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;

			case SpecialWeaponType::grkt:
			{
				this.set_u16("GRKT", 57);
				this.set_netid("target_GRKT",targetID);
			}
			break;

			case SpecialWeaponType::eml:
			{
				CBlob@ missile = server_CreateBlobNoInit("eml");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + Vec2f(0.0f, -8.0f).RotateBy(this.getAngleDegrees()));
					missile.setVelocity(Vec2f(0.0f, -50.0f).RotateBy(this.getAngleDegrees()));
	
				}
			}
			break;

			case SpecialWeaponType::mgp:
			{
				CBlob@ bullet0 = server_CreateBlobNoInit("bullet");
				if (bullet0 !is null)
				{
					bullet0.SetDamageOwnerPlayer(this.getPlayer());
					bullet0.Init();
				
					bullet0.IgnoreCollisionWhileOverlapped(this);
					bullet0.server_setTeamNum(this.getTeamNum());
					bullet0.setPosition(this.getPosition() + Vec2f(6.0f, 0.0f).RotateBy(this.getAngleDegrees()));
					bullet0.setVelocity(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));
				}
				CBlob@ bullet1 = server_CreateBlobNoInit("bullet");
				if (bullet1 !is null)
				{
					bullet1.SetDamageOwnerPlayer(this.getPlayer());
					bullet1.Init();
				
					bullet1.IgnoreCollisionWhileOverlapped(this);
					bullet1.server_setTeamNum(this.getTeamNum());
					bullet1.setPosition(this.getPosition() + Vec2f(-6.0f, 0.0f).RotateBy(this.getAngleDegrees()));
					bullet1.setVelocity(Vec2f(0.0f, -25.0f).RotateBy(this.getAngleDegrees()));
				}
			}
			break;

			case SpecialWeaponType::plsl:
			{
				CBlob@ missile = server_CreateBlobNoInit("plsl");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1) + Vec2f(0.0f, -8.0f)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity(Vec2f(0.0f, -50.0f).RotateBy(this.getAngleDegrees()));
	
				}
			}
			break;


			case SpecialWeaponType::tls:
			{
				this.set_u16("TLS", 150);
			}
			break;


			case SpecialWeaponType::uav:
			{
				CBlob@ missile = server_CreateBlobNoInit("uav");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(6.0f, 0.0f) * (number == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;


			case SpecialWeaponType::mpbm:
			{
				CBlob@ missile = server_CreateBlobNoInit("mpbm");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition());
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;


			case SpecialWeaponType::iews:
			{
				this.set_u16("IEWS", 300);
			}
			break;


			case SpecialWeaponType::mstm:
			{
				CBlob@ missile = server_CreateBlobNoInit("mstm");
				if (missile !is null)
				{
					missile.SetDamageOwnerPlayer(this.getPlayer());
					missile.set_netid("target" ,targetID);
					missile.Init();
				
					if (ecm) missile.Tag("ECM");
					if (esm) missile.Tag("ESM");
					missile.IgnoreCollisionWhileOverlapped(this);
					missile.server_setTeamNum(this.getTeamNum());
					missile.setPosition(this.getPosition() + (Vec2f(number >= 2 ? 8.0f : 6.0f, 0.0f) * (number % 2 == 0 ? 1 : -1)).RotateBy(this.getAngleDegrees()));
					missile.setVelocity((Vec2f(0.0f, -1.0f).RotateBy(this.getAngleDegrees())) * this.getVelocity().getLength());
	
				}
			}
			break;
		}

		CBitStream params;
		params.write_u8(type);
		this.SendCommand(this.getCommandID("shoot special client"), params);
	}
	else if (cmd == this.getCommandID("shoot special client") && isClient())
	{
		u8 type;
		if (!params.saferead_u8(type)) return;

		if (type == SpecialWeaponType::mgp) Sound::Play("M16Fire.ogg", this.getPosition());
		// same sound :p
		else Sound::Play("ProduceSound.ogg", this.getPosition());

		switch (type)
		{
			case SpecialWeaponType::grkt:
				this.set_u16("GRKT", 57);
			break;

			case SpecialWeaponType::tls:
				this.set_u16("TLS", 150);
			break;

			case SpecialWeaponType::iews:
				this.set_u16("IEWS", 300);
			break;
		}
	}
	else if (cmd == this.getCommandID("shoot flare") && isServer())
	{
		CBlob@[] missiles;
		if (getMap().getBlobsInRadius(this.getPosition(), 250.0f, @missiles))
		{
			for (int i = 0; i < missiles.size(); i++)
			{
				CBlob@ missile = missiles[i];
				if (missile.get_netid("target") == 0xFFFF) continue;
				CBlob@ target = getBlobByNetworkID(missile.get_netid("target"));
				if (target is this)
				{
					missile.set_netid("target", 0xFFFF);
					missile.Sync("target", true);
				}
			}
		}

		CBlob@ flare = server_CreateBlob("flare");
		if (flare !is null)
		{
			flare.setPosition(this.getPosition());
			flare.setVelocity(Vec2f(0.0f, -10.0f).RotateBy(this.getAngleDegrees()));
		}

		this.SendCommand(this.getCommandID("shoot flare client"));
	}
	else if (cmd == this.getCommandID("shoot flare client") && isClient())
	{
		Sound::Play("FireFwoosh.ogg", this.getPosition());
	}

	// landing and take off
	else if (cmd == this.getCommandID("landing") && isServer())
	{
		this.Tag("landed");
		this.SendCommand(this.getCommandID("landing client"));
	}
	else if (cmd == this.getCommandID("landing client") && isClient())
	{
		this.Tag("landed");
	}
	else if (cmd == this.getCommandID("take off") && isServer())
	{
		this.Untag("landed");
		this.SendCommand(this.getCommandID("take off client"));
	}
	else if (cmd == this.getCommandID("take off client") && isClient())
	{
		this.Untag("landed");
	}/*
	else if (cmd == this.getCommandID("change special") && isServer())
	{
		u8 type;
		if (!params.saferead_u8(type)) return;
		// need?
		PlaneInfo@ plane;
		if (!this.get("planeInfo", @plane))
		{
			return;
		}
		plane.special_type = type;

		CBitStream params;
		params.write_u8(type);
		this.SendCommand(this.getCommandID("change special client"), params);
	}
	else if (cmd == this.getCommandID("change special client") && isClient())
	{
		u8 type;
		if (!params.saferead_u8(type)) return;
		// need?
		PlaneInfo@ plane;
		if (!this.get("planeInfo", @plane))
		{
			return;
		}
		plane.special_type = type;
	}*/
}

void Callback_ChangeSpecial(CBitStream@ params)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null) return;

	CBlob@ blob = player.getBlob();
	if (blob is null) return;

	u8 type;
	if (!params.saferead_u8(type)) return;
	// need?
	PlaneInfo@ plane;
	if (!blob.get("planeInfo", @plane))
	{
		return;
	}
	plane.special_type = type;
}

// no damage while landing
// no damage from your sasm
f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (this.hasTag("landed")) return 0.0f;
	else if (customData == Hitters::explosion && this.getPlayer() is hitterBlob.getDamageOwnerPlayer()) return 0.0f;
	else return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	//only collide with projectiles
	if (blob.hasTag("projectile") && this.getTeamNum() != blob.getTeamNum())
	{
		return true;
	}

	return false;
}

// clash
void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (solid)
	{
		if (blob is null)
		{
			this.server_Die();
		}
	}
}

// CAMERA

void onRender(CBlob@ this)
{
	//do 60fps camera
	if (!this.isMyPlayer()) return;
	AdjustCamera(this, true);
}

void AdjustCamera(CBlob@ this, bool is_in_render)
{
	CCamera@ camera = getCamera();
	f32 zoom = camera.targetDistance;

	camera.setRotation(this.getAngleDegrees());

	f32 zoomSpeed = 0.1f;
	if (is_in_render)
	{
		zoomSpeed *= getRenderApproximateCorrectionFactor();
	}

	f32 minZoom = 0.5f; // TODO: make vars
	f32 maxZoom = 2.0f;

	f32 zoom_target = 1.0f;

	if (zoomModifier) 
	{
		switch (zoomModifierLevel) 
		{
			case 0:	zoom_target = 0.03125f; zoomLevel = 0; break;
			case 1: zoom_target = 0.0625f; zoomLevel = 1; break;
			case 2: zoom_target = 0.125f; zoomLevel = 2; break;
			case 3: zoom_target = 0.25f; zoomLevel = 3; break;
			case 4: zoom_target = 0.5f; zoomLevel = 4; break;
			case 5: zoom_target = 1.0f; zoomLevel = 5; break;
			case 6: zoom_target = 2.0f; zoomLevel = 6; break;
		}
	} 
	else 
	{
		switch (zoomLevel) 
		{
			case 0:	zoom_target = 0.03125f; zoomModifierLevel = 0; break;
			case 1: zoom_target = 0.0625f; zoomModifierLevel = 1; break;
			case 2: zoom_target = 0.125f; zoomModifierLevel = 2; break;
			case 3: zoom_target = 0.25f; zoomModifierLevel = 3; break;
			case 4: zoom_target = 0.5f; zoomModifierLevel = 4; break;
			case 5: zoom_target = 1.0f; zoomModifierLevel = 5; break;
			case 6: zoom_target = 2.0f; zoomModifierLevel = 6; break;
		}
	}

	if (zoom > zoom_target)
	{
		zoom = Maths::Max(zoom_target, zoom - zoomSpeed);
	}
	else if (zoom < zoom_target)
	{
		zoom = Maths::Min(zoom_target, zoom + zoomSpeed);
	}

	camera.targetDistance = zoom;
}

void ManageCamera(CBlob@ this)
{
	CCamera@ camera = getCamera();
	if (camera is null)
	{
		return;
	}
	CControls@ controls = this.getControls();

	// mouse look & zoom
	if ((getGameTime() - this.get_s32("tap_time") > 5) && controls !is null)
	{
		if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMOUT)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Max(0, zoomModifierLevel - 1);
			zoomLevel = Maths::Max(0, zoomLevel - 1);

			Tap(this);
		}
		else  if (controls.isKeyJustPressed(controls.getActionKeyKey(AK_ZOOMIN)))
		{
			zoomModifier = controls.isKeyPressed(KEY_LCONTROL);

			zoomModifierLevel = Maths::Min(6, zoomModifierLevel + 1);
			zoomLevel = Maths::Min(6, zoomLevel + 1);

			Tap(this);
		}
	}

	if (!this.hasTag("60fps_camera"))
	{
		AdjustCamera(this, false);
	}

	f32 zoom = camera.targetDistance;
	bool fixedCursor = true;
	if (g_fixedcamera) // option
	{
		camera.mousecamstyle = 1; // fixed
	}
	else
	{
		camera.mousecamstyle = 2; // soldatstyle
	}

	// camera
	camera.mouseFactor = 0.5f; // doesn't affect soldat cam
}
