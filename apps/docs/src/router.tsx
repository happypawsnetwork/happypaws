import { createBrowserRouter } from "react-router";
import { RootLayout } from "@/layouts/RootLayout";
import { ProjectOverviewPage } from "@/pages/ProjectOverviewPage";
import { UserRolesPage } from "@/pages/UserRolesPage";
import { RoleStoriesPage } from "@/pages/RoleStoriesPage";
import { ApiSpecPage } from "@/pages/ApiSpecPage";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <RootLayout />,
    children: [
      {
        index: true,
        element: <ProjectOverviewPage />,
      },
      {
        path: "user-roles",
        element: <UserRolesPage />,
      },
      {
        path: "stories/:roleId",
        element: <RoleStoriesPage />,
      },
      {
        path: "stories/:roleId/:storyId",
        element: <RoleStoriesPage />,
      },
      {
        path: "api-spec",
        element: <ApiSpecPage />,
      },
      {
        path: "api-spec/:topicId",
        element: <ApiSpecPage />,
      },
    ],
  },
]);
