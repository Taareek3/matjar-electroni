import { Request, Response } from "express";
import { prisma } from "../config/database";
import { sendSuccess } from "../utils/response";

export async function getMenu(_req: Request, res: Response): Promise<void> {
  const categories = await prisma.category.findMany({
    orderBy: { position: "asc" },
  });

  const items = await prisma.menuItem.findMany({
    where: { isAvailable: true },
    orderBy: { position: "asc" },
    include: {
      optionGroups: {
        orderBy: { position: "asc" },
        include: {
          options: { orderBy: { position: "asc" } },
        },
      },
    },
  });

  sendSuccess(
    res,
    {
      categories: categories.map((category) => ({
        id: category.id,
        name: category.name,
        image: category.image,
      })),
      items: items.map((item) => ({
        id: item.id,
        name: item.name,
        description: item.description ?? "",
        price: item.basePrice,
        imageUrl: item.image ?? "",
        categoryId: item.categoryId,
        optionGroups: item.optionGroups.map((group) => ({
          id: group.id,
          title: group.name,
          isRequired: group.isRequired,
          allowMultiple: group.allowMultiple,
          options: group.options.map((option) => ({
            id: option.id,
            name: option.name,
            additionalPrice: option.price,
          })),
        })),
      })),
    },
    "تم جلب المنيو بنجاح",
  );
}
