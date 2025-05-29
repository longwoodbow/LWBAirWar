//plane HUD
#include "PlaneCommon.as";

void onInit(CSprite@ this)
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	this.getCurrentScript().removeIfTag = "dead";
	getHUD().SetDefaultCursor();
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
	CControls@ c = getControls();
	if (c is null) return;
	Vec2f spos = c.getMouseScreenPos() + Vec2f(0.0f, 12.0f * cl_mouse_scale);

	f32 zoom = getCamera().targetDistance;

	// Check IEWS
	CBlob@[] planes;
	if (getBlobsByTag("player", @planes))
	{
		for (int i = 0; i < planes.size(); i++)
		{
			CBlob@ plane = planes[i];
			if (plane.exists("IEWS") && plane.get_u16("IEWS") > 0)
			{
				GUI::DrawCircle(plane.getScreenPos(), 500.0f * Maths::Pi * zoom, plane.getTeamNum() == 1 ? SColor(0xff, 0xff, 0x00, 0x00) :  SColor(0xff, 0x00, 0x00, 0xFF));
			}
		}
	}
	// show radar
	u16 range = plane.use_special ? specialRanges[plane.special_type] : missile_range;
	GUI::DrawCircle(blob.getScreenPos(), range * Maths::Pi * zoom, SColor(0xff, 0x00, 0xff, 0x00));
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

				GUI::DrawLine(pos + angle * 40, pos + angle * 50, SColor(0xff, 0xff, 0x00, 0x00));

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

		GUI::DrawText((!plane.use_special ? ">" : "") + "MSL:" + plane.amount_missile, spos, color);
		GUI::DrawText((plane.use_special ? ">" : "") + specialTypeNames[plane.special_type] + ":" + plane.amount_special, spos + Vec2f(0.0f, 10.0f), color);
		GUI::DrawText("FLR:" + plane.amount_flare, spos + Vec2f(0.0f, 20.0f), color);
		GUI::DrawText("DMG:" + (100.0f - blob.getHealth() / blob.getInitialHealth() * 100) + "%", spos + Vec2f(0.0f, 30.0f), color);

		if (alert) GUI::DrawTextCentered("MISSILE ALERT", blob.getScreenPos() + Vec2f(0.0f, 42.0f), color);

		if (blob.hasTag("ECM")) GUI::DrawTextCentered("ECM ACTIVATED", blob.getScreenPos() + Vec2f(0.0f, -42.0f), color);
		if (blob.hasTag("ESM")) GUI::DrawTextCentered("ESM ACTIVATED", blob.getScreenPos() + Vec2f(0.0f, -52.0f), color);

		if (u_showtutorial)
		{
			GUI::DrawText("W:Accel", spos + Vec2f(0.0f, 50.0f), color);
			GUI::DrawText("S:Brake", spos + Vec2f(0.0f, 60.0f), color);
			GUI::DrawText("A/D:Yaw", spos + Vec2f(0.0f, 70.0f), color);
			GUI::DrawText("E on ally base: Landing and get Resupply/Take off", spos + Vec2f(0.0f, 80.0f), color);
			GUI::DrawText("F:Active/Deactive Special Weapon", spos + Vec2f(0.0f, 90.0f), color);
			GUI::DrawText("C:Change target", spos + Vec2f(0.0f, 100.0f), color);
			GUI::DrawText("Space:Flare", spos + Vec2f(0.0f, 110.0f), color);

			GUI::DrawText("Kill enemies until tickets get empty or destroy enemy base to win", spos + Vec2f(0.0f, 130.0f), color);

			GUI::DrawText("Press F1 to hide controls", spos + Vec2f(0.0f, 150.0f), color);
		}
		else
		{
			GUI::DrawText("Press F1 to show controls", spos + Vec2f(0.0f, 50.0f), color);
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
}