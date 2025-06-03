//plane HUD
#include "PlaneCommon.as";
#include "TeamColour.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	getHUD().SetDefaultCursor();
}

bool IsOnScreen(Vec2f pos)
{
	//CBlob.isOnScreen is useless
	return pos.x >= 0.0f && pos.x <= getScreenWidth() && pos.y >= 0.0f && pos.y <= getScreenHeight();
}

void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	CCamera@ camera = getCamera();
	float cameraAngle = 0.0f;
	if (camera !is null) cameraAngle = camera.getRotation();

	PlaneInfo@ plane;
	if (!blob.get("planeInfo", @plane))
	{
		return;
	}

	Vec2f pos = blob.getPosition();
	Vec2f spos = blob.getScreenPos();
	CControls@ c = getControls();
	if (c is null) return;
	Vec2f cpos = c.getMouseScreenPos() + Vec2f(0.0f, 12.0f * cl_mouse_scale);

	f32 zoom = getCamera().targetDistance;

	CBlob@[] planes;
	if (getBlobsByTag("player", @planes))
	{
		for (int i = 0; i < planes.size(); i++)
		{
			CBlob@ otherPlane = planes[i];
			SColor teamColor = getTeamColor(otherPlane.getTeamNum());
			Vec2f planePos = otherPlane.getPosition();

			if (!IsOnScreen(otherPlane.getScreenPos()) && !otherPlane.isMyPlayer())
			{
				Vec2f angleVec = planePos - pos;
				angleVec.Normalize();
				GUI::DrawArrow(pos + angleVec * 125.0f / zoom, pos + angleVec * 150.0f / zoom, teamColor);
			}
		}
	}

	CBlob@[] bases;
	if (getBlobsByName("airwar_base", @bases))
	{
		for (int i = 0; i < bases.size(); i++)
		{
			CBlob@ base = bases[i];
			SColor teamColor = getTeamColor(base.getTeamNum());
			Vec2f basePos = base.getPosition();

			if (!IsOnScreen(base.getScreenPos()))
			{
				Vec2f angleVec = basePos - pos;
				angleVec.Normalize();
				GUI::DrawArrow(pos + angleVec * 60.0f / zoom, pos + angleVec * 110.0f / zoom, teamColor);
			}
		}
	}

	// show radar
	u16 range = plane.use_special ? specialRanges[plane.special_type] : missile_range;
	GUI::DrawCircle(spos, range * Maths::Pi * zoom, SColor(0xff, 0x00, 0xff, 0x00));
	u16 arc = plane.use_special ? specialArcs[plane.special_type] : missile_arc;
	GUI::DrawLine(pos, pos + Vec2f(0.0f, -range).RotateBy(blob.getAngleDegrees() + arc / 2.0f), SColor(0xff, 0x00, 0xff, 0x00));
	GUI::DrawLine(pos, pos + Vec2f(0.0f, -range).RotateBy(blob.getAngleDegrees() - arc / 2.0f), SColor(0xff, 0x00, 0xff, 0x00));

	CBlob@ target;
	if (blob.get("target0", @target))
	{
		GUI::DrawCircle(target.getScreenPos(), 24.0f * zoom, SColor(0xff, 0x00, 0xff, 0x00));
	}
	if (blob.get("target1", @target))
	{
		GUI::DrawCircle(target.getScreenPos(), 24.0f * zoom, SColor(0xff, 0x00, 0xff, 0x00));
	}
	if (blob.get("target2", @target))
	{
		GUI::DrawCircle(target.getScreenPos(), 24.0f * zoom, SColor(0xff, 0x00, 0xff, 0x00));
	}
	if (blob.get("target3", @target))
	{
		GUI::DrawCircle(target.getScreenPos(), 24.0f * zoom, SColor(0xff, 0x00, 0xff, 0x00));
	}

	// weapons reloading
	if (plane.use_special)
	{
		if (specialCharges[plane.special_type] > 0)
		{
			Vec2f start = pos + Vec2f(16.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-plane.special_time_0 + specialCooldowns[plane.special_type]) / specialCooldowns[plane.special_type];
			Vec2f end = pos + Vec2f(16.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (plane.special_time_0 <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}

		if (specialCharges[plane.special_type] > 1 || plane.special_type == SpecialWeaponType::mgp)
		{
			Vec2f start = pos + Vec2f(-16.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-((plane.special_type == SpecialWeaponType::mgp) ? plane.special_time_0 : plane.special_time_1) + specialCooldowns[plane.special_type]) / specialCooldowns[plane.special_type];
			Vec2f end = pos + Vec2f(-16.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (((plane.special_type == SpecialWeaponType::mgp) ? plane.special_time_0 : plane.special_time_1) <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}

		if (specialCharges[plane.special_type] > 2)
		{
			Vec2f start = pos + Vec2f(14.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-plane.special_time_2 + specialCooldowns[plane.special_type]) / specialCooldowns[plane.special_type];
			Vec2f end = pos + Vec2f(14.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (plane.special_time_2 <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}

		if (specialCharges[plane.special_type] > 3)
		{
			Vec2f start = pos + Vec2f(-14.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-plane.special_time_3 + specialCooldowns[plane.special_type]) / specialCooldowns[plane.special_type];
			Vec2f end = pos + Vec2f(-14.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (plane.special_time_3 <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}
	}
	else
	{
		// missile 0
		{
			Vec2f start = pos + Vec2f(16.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-plane.missile_time_0 + missile_cooldown) / missile_cooldown;
			Vec2f end = pos + Vec2f(16.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (plane.missile_time_0 <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}

		// missile 1
		{
			Vec2f start = pos + Vec2f(-16.0f, 16.0f).RotateBy(cameraAngle) / zoom;
			f32 dif = 32.0f * (-plane.missile_time_1 + missile_cooldown) / missile_cooldown;
			Vec2f end = pos + Vec2f(-16.0f, 16.0f - dif).RotateBy(cameraAngle) / zoom;

			SColor color = (plane.missile_time_1 <= 0) ? SColor(0xff, 0x00, 0xff, 0x00) : SColor(0xff, 0xFF, 0xff, 0xFF);

			GUI::DrawLine(start, end, color);
		}
	}

	// missile alert
	CBlob@[] missiles;
	bool alert = false;
	if (getBlobsByTag("homing", @missiles))
	{
		for (int i = 0; i < missiles.size(); i++)
		{
			CBlob@ missile = missiles[i];
			if (missile.get_netid("target") == 0xFFFF) continue;
			CBlob@ target = getBlobByNetworkID(missile.get_netid("target"));
			if (target is blob)
			{
				Vec2f angle = missile.getPosition() - blob.getPosition();
				angle.Normalize();

				GUI::DrawArrow(pos + angle * 40.0f / zoom, pos + angle * 50.0f / zoom, SColor(0xff, 0xff, 0x00, 0x00));

				alert = true;
			}
		}
	}

	// upper end and strings
	{
		Vec2f start = pos + Vec2f(-16.0f, -16.0f).RotateBy(cameraAngle) / zoom;
		Vec2f end = pos + Vec2f(16.0f, -16.0f).RotateBy(cameraAngle) / zoom;

		// check missiles

		SColor color = alert ? SColor(0xff, 0xff, 0x00, 0x00) : SColor(0xff, 0xff, 0xff, 0xff);

		GUI::DrawLine(start, end, color);

		GUI::SetFont("menu");

		GUI::DrawText((!plane.use_special ? ">" : "") + "MSL:" + plane.amount_missile, cpos, color);
		GUI::DrawText((plane.use_special ? ">" : "") + specialTypeNames[plane.special_type] + ":" + plane.amount_special, cpos + Vec2f(0.0f, 10.0f), color);
		GUI::DrawText("FLR:" + plane.amount_flare, cpos + Vec2f(0.0f, 20.0f), color);
		GUI::DrawText("DMG:" + (100.0f - blob.getHealth() / blob.getInitialHealth() * 100) + "%", cpos + Vec2f(0.0f, 30.0f), color);

		if (alert) GUI::DrawTextCentered("MISSILE ALERT", spos + Vec2f(0.0f, 42.0f), color);

		if (blob.hasTag("ECM")) GUI::DrawTextCentered("ECM ACTIVATED", spos + Vec2f(0.0f, -42.0f), color);
		if (blob.hasTag("ESM")) GUI::DrawTextCentered("ESM ACTIVATED", spos + Vec2f(0.0f, -52.0f), color);

		if (u_showtutorial)
		{
			GUI::DrawText("W:Accel", cpos + Vec2f(0.0f, 50.0f), color);
			GUI::DrawText("S:Brake", cpos + Vec2f(0.0f, 60.0f), color);
			GUI::DrawText("A/D:Yaw", cpos + Vec2f(0.0f, 70.0f), color);
			GUI::DrawText("E on ally base: Landing and get Resupply/Take off", cpos + Vec2f(0.0f, 80.0f), color);
			GUI::DrawText("F:Active/Deactive Special Weapon", cpos + Vec2f(0.0f, 90.0f), color);
			GUI::DrawText("C:Change target", cpos + Vec2f(0.0f, 100.0f), color);
			GUI::DrawText("Space:Flare", cpos + Vec2f(0.0f, 110.0f), color);

			GUI::DrawText("Kill enemies until tickets get empty or destroy enemy base to win", cpos + Vec2f(0.0f, 130.0f), color);

			GUI::DrawText("Press F1 to hide controls", cpos + Vec2f(0.0f, 150.0f), color);
		}
		else
		{
			GUI::DrawText("Press F1 to show controls", cpos + Vec2f(0.0f, 50.0f), color);
		}
	}

	// health
	{
		Vec2f start = pos + Vec2f(-16.0f, 16.0f).RotateBy(cameraAngle) / zoom;
		f32 initHealth = blob.getInitialHealth();
		f32 health = blob.getHealth();
		f32 dif = 32.0f * health / initHealth;
		Vec2f end = pos + Vec2f(-16.0f + dif, 16.0f).RotateBy(cameraAngle) / zoom;

		SColor color = (health >= initHealth) ? SColor(0xff, 0x00, 0xff, 0x00) :
					   (health > initHealth * 0.5f) ? SColor(0xff, 0xff, 0xff, 0xff) :
					   (health > initHealth * 0.2f) ? SColor(0xff, 0xff, 0xff, 0x00) :
					   SColor(0xff, 0xff, 0x00, 0x00);
		GUI::DrawLine(start, end, color);
	}

	// hit and destroyed message
	if (blob.get_u32("hit_message") > getGameTime())
	{
		SColor color = SColor(0xff, 0x00, 0xff, 0x00);
		if(blob.get_bool("destroyed_message"))
		{
			GUI::DrawTextCentered("DESTROYED", spos + Vec2f(0.0f, 30.0f), color);
		}
		else
		{
			GUI::DrawTextCentered("HIT", spos + Vec2f(0.0f, 30.0f), color);
		}
	}
}