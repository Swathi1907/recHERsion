import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { getRoutesController } from "../controllers/routes.controller";

export const routesRouter = Router();

routesRouter.get("/", asyncHandler(getRoutesController));
