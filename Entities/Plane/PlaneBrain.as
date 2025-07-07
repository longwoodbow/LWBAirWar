// Plane brain

#define SERVER_ONLY

#include "PlaneCommon.as"

void onInit(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	blob.set_u32("missile time", getGameTime());
}


void onTick(CBrain@ this)
{
	CBlob@ blob = this.getBlob();
	Vec2f pos = blob.getPosition();

	CBlob@ target = this.getTarget();

	CBlob@[] planes;
	f32 shortest = 10000.0f;
	if (getBlobsByTag("player", @planes))
	{
		bool findPlane = false;
		for (int i = 0; i < planes.size(); i++)
		{
			CBlob@ plane = planes[i];
			if (!blob.hasTag("dead") && !blob.hasTag("landed") && blob.getTeamNum() != plane.getTeamNum())
			{
				f32 length = (plane.getPosition() - pos).getLength();
				if (!findPlane || length < shortest)
				{
					findPlane = true;
					this.SetTarget(plane);
					@target = @plane;
					shortest = length;
				}
			}
		}
	}

	// take off
	if (blob.hasTag("landed") && !blob.wasKeyPressed(key_use))
	{
		blob.setKeyPressed(key_use, true);
	}

	// find target if looks easier to hit
	// should I make?

	// shoot bullets if enemies are near
	if (shortest < 100.0f)
	{
		blob.setKeyPressed(key_action1, true);
	}

	// shoot missile if enemy is in radar
	const u32 gametime = getGameTime();
	u32 missileTime;
	CBlob@ inRadar = null;
	if (blob.get_u32("missile time") < gametime && blob.get("target0", @inRadar) && inRadar !is null)
	{
		blob.set_u32("missile time", gametime + 14);
		blob.setKeyPressed(key_action2, true);
	}

	// movement
	f32 angle = blob.getAngleDegrees();

	// try to dodge missiles	

	// follow target

	if (target !is null)
	{
		f32 targetAngle = -(target.getPosition() - pos).getAngle() + 90.0f - angle;

		while (targetAngle > 180.0f)
		{
			targetAngle -= 360.0f;
		}

		while (targetAngle < -180.0f)
		{
			targetAngle += 360.0f;
		}

		if (targetAngle < 0.0f)
		{
			blob.setKeyPressed(key_left, true);
		}
		else
		{
			blob.setKeyPressed(key_right, true);
		}
	}

	// use flare
}