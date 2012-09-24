/*****************************************************************************
 *                                                                            *
 *  OpenNI 1.0 Alpha                                                          *
 *  Copyright (C) 2010 PrimeSense Ltd.                                        *
 *                                                                            *
 *  This file began as part of OpenNI, now heavily modified                   *
 *                                                                            *
 *****************************************************************************/

#ifndef XNV_POINT_DRAWER_H_
#define XNV_POINT_DRAWER_H_

#include <XnCppWrapper.h>

void DrawDepthMap(const xn::DepthMetaData& dmd, const xn::SceneMetaData& smd);
void DrawUserInfo();

#endif