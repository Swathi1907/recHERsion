import { Router } from "express";
import { asyncHandler } from "../utils/asyncHandler";
import { getRoutesController,searchDestinationsController } from "../controllers/routes.controller";

export const routesRouter = Router();

routesRouter.get("/", asyncHandler(getRoutesController));
routesRouter.get("/search", asyncHandler(searchDestinationsController));