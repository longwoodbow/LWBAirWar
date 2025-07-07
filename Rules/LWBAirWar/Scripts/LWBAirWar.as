#include "Default/DefaultGUI.as"
#include "Default/DefaultLoaders.as"
#include "PrecacheTextures.as"
#include "EmotesCommon.as"
#include "TeamColour.as";

void onInit(CRules@ this)
{
	LoadDefaultMapLoaders();
	LoadDefaultGUI();

	// comment this out if you want to restore legacy net command script
	// compatibility. mods that include scripts from before build 4541 may
	// additionally want to bring back scripts they share commands with.
	getNet().legacy_cmd = true;

	if (isServer())
	{
		getSecurity().reloadSecurity();
	}

	sv_gravity = 0.0f;
	particles_gravity.y = 0.0f;
	sv_visiblity_scale = 1.25f;
	cc_halign = 2;
	cc_valign = 2;

	s_effects = false;

	sv_max_localplayers = 1;

	v_showminimap = false;

	PrecacheTextures();

	//smooth shader
	Driver@ driver = getDriver();

	driver.AddShader("hq2x", 1.0f);
	driver.SetShader("hq2x", true);

	//reset var if you came from another gamemode that edits it
	SetGridMenusSize(24,2.0f,32);

	//also restart stuff
	onRestart(this);
}

bool need_sky_check = true;
void onRestart(CRules@ this)
{
	//map borders
	CMap@ map = getMap();
	if (map !is null)
	{
		map.SetBorderFadeWidth(24.0f);
		map.SetBorderColourTop(SColor(0xff000000));
		map.SetBorderColourLeft(SColor(0xff000000));
		map.SetBorderColourRight(SColor(0xff000000));
		map.SetBorderColourBottom(SColor(0xff000000));

		//do it first tick so the map is definitely there
		//(it is on server, but not on client unfortunately)
		need_sky_check = true;
	}
}

void onTick(CRules@ this)
{
	sv_gravity = 0.0f;
	/*
	//TODO: figure out a way to optimise so we don't need to keep running this hook
	if (need_sky_check)
	{
		need_sky_check = false;
		CMap@ map = getMap();
		//find out if there's any solid tiles in top row
		// if not - semitransparent sky
		// if yes - totally solid, looks buggy with "floating" tiles
		bool has_solid_tiles = false;
		for(int i = 0; i < map.tilemapwidth; i++) {
			if(map.isTileSolid(map.getTile(i))) {
				has_solid_tiles = true;
				break;
			}
		}
		map.SetBorderColourTop(SColor(has_solid_tiles ? 0xff000000 : 0x80000000));
	}
	*/
}

void onRender(CRules@ this)
{
	CCamera@ camera = getCamera();
	if (camera is null) return;

	f32 zoom = camera.targetDistance;

	// marks
	CBlob@[] planes;
	if (getBlobsByTag("player", @planes))
	{
		for (int i = 0; i < planes.size(); i++)
		{
			CBlob@ otherPlane = planes[i];
			SColor teamColor = getTeamColor(otherPlane.getTeamNum());
			Vec2f planePos = otherPlane.getPosition();

			if (!otherPlane.isMyPlayer())
			{
				Vec2f point0 = planePos + Vec2f(-8.0f, -8.0f).RotateBy(camera.getRotation()) / zoom;
				Vec2f point1 = planePos + Vec2f(8.0f, -8.0f).RotateBy(camera.getRotation()) / zoom;
				Vec2f point2 = planePos + Vec2f(8.0f, 8.0f).RotateBy(camera.getRotation()) / zoom;
				Vec2f point3 = planePos + Vec2f(-8.0f, 8.0f).RotateBy(camera.getRotation()) / zoom;
				GUI::DrawLine(point0, point1, teamColor);
				GUI::DrawLine(point1, point2, teamColor);
				GUI::DrawLine(point2, point3, teamColor);
				GUI::DrawLine(point3, point0, teamColor);
			}

			// Check IEWS
			if (otherPlane.exists("IEWS") && otherPlane.get_u16("IEWS") > 0)
			{
				GUI::DrawCircle(otherPlane.getScreenPos(), 500.0f * Maths::Pi * zoom, teamColor);
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

			Vec2f point0 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation()) / zoom;
			Vec2f point1 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation() - 60) / zoom;
			Vec2f point2 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation() - 120) / zoom;
			Vec2f point3 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation() - 180) / zoom;
			Vec2f point4 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation() + 120) / zoom;
			Vec2f point5 = basePos + Vec2f(8.0f, 0.0f).RotateBy(camera.getRotation() + 60) / zoom;
			GUI::DrawLine(point0, point1, teamColor);
			GUI::DrawLine(point1, point2, teamColor);
			GUI::DrawLine(point2, point3, teamColor);
			GUI::DrawLine(point3, point4, teamColor);
			GUI::DrawLine(point4, point5, teamColor);
			GUI::DrawLine(point5, point0, teamColor);
		}
	}

	// minimap
	
}

//chat stuff!

void onEnterChat(CRules @this)
{
	if (getChatChannel() != 0) return; //no dots for team chat

	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "dots", 100000);
}

void onExitChat(CRules @this)
{
	CBlob@ localblob = getLocalPlayerBlob();
	if (localblob !is null)
		set_emote(localblob, "", 0);
}
