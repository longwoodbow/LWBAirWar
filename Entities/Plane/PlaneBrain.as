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

	CBlob@ allyBase = null;
	// if have no target, base is the target
	CBlob@[] bases;
	if (getBlobsByName("airwar_base", @bases))
	{
		for (int i = 0; i < bases.size(); i++)
		{
			CBlob@ base = bases[i];
			if (blob.getTeamNum() != base.getTeamNum() && target is null)
			{
				shortest = (base.getPosition() - pos).getLength();
				this.SetTarget(base);
				@target = @base;
			}
			else if (blob.getTeamNum() == base.getTeamNum())
			{
				@allyBase = @base;
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

	bool retreat = false;
	PlaneInfo@ planeInfo;
	if (!blob.get("planeInfo", @planeInfo))
	{
		return;
	}

	if (blob.getHealth() <= blob.getInitialHealth() / 2.0f || planeInfo.amount_missile <= 0)
		retreat = true;

	// try to dodge missiles	

	bool dodge = false;
	CBlob@[] missiles;
	f32 shortestMissile = 10000.0f;
	if (getBlobsByTag("projectile", @missiles))
	{
		for (int i = 0; i < missiles.size(); i++)
		{
			CBlob@ missile = missiles[i];
			if (blob.getTeamNum() != missile.getTeamNum())
			{
				Vec2f missilePos = missile.getPosition() - pos;
				f32 missileAngle = missilePos.getAngle();
				f32 missileVelAngle = (-missile.getVelocity()).getAngle();
				f32 length = missilePos.getLength();

				f32 dif = missileAngle - missileVelAngle;
				while (dif > 180.0f)
				{
					dif -= 360.0f;
				}
				while (dif < -180.0f)
				{
					dif += 360.0f;
				}

				if (dif < 20.0f && dif > -20.0f && length < shortest)
				{
					dodge = true;
					shortest = length;

					f32 dodgeAngle = missileVelAngle - 90.0f + angle;
					while (dodgeAngle > 180.0f)
					{
						dodgeAngle -= 360.0f;
					}
					while (dodgeAngle < -180.0f)
					{
						dodgeAngle += 360.0f;
					}

					blob.setKeyPressed(key_up, true);

					if (dodgeAngle > 90.0f || (dodgeAngle < 0.0f && dodgeAngle > -90.0f))
					{
						blob.setKeyPressed(key_left, true);
						blob.setKeyPressed(key_right, false);
					}
					else
					{
						blob.setKeyPressed(key_left, false);
						blob.setKeyPressed(key_right, true);
					}
				}
			}
		}
	}

	if (!dodge && retreat && allyBase !is null)
	{
		Vec2f targetPos = allyBase.getPosition() - pos;
		f32 targetLength = targetPos.getLength();
		f32 targetAngle = -(targetPos).getAngle() + 90.0f - angle;

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

		if (targetLength > 250.0f)
		{
			blob.setKeyPressed(key_up, true);
		}
		else
		{
			blob.setKeyPressed(key_down, true);
		}

		CBlob@[] overlapping;
		if (blob.getOverlapping(@overlapping))
		{
			for(int i = 0; i < overlapping.size(); i++)
			{
				CBlob@ b = overlapping[i];
				if (b.getName() == "airwar_base" && blob.getTeamNum() == b.getTeamNum())
				{
					blob.setKeyPressed(key_use, true);
					break;
				}
			}
		}
	}
	// follow target
	else if (!dodge && target !is null)
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


		if (shortest > 1000.0f)
		{
			blob.setKeyPressed(key_up, true);
		}
		else
		{
			blob.setKeyPressed(key_down, true);
		}
	}

	// use flare
}