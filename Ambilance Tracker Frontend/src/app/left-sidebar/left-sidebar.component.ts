import { CommonModule } from '@angular/common';
import { Component, input, output } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-left-sidebar',
  standalone: true,
  imports: [RouterModule, CommonModule],
  templateUrl: './left-sidebar.component.html',
  styleUrl: './left-sidebar.component.css',
})
export class LeftSidebarComponent {
  isLeftSidebarCollapsed = input.required<boolean>();
  changeIsLeftSidebarCollapsed = output<boolean>();
  items = [
    {
      routeLink: 'dashboard',
      icon: 'fal fa-home',
      label: 'Dashboard',
    },
    {
      routeLink: 'cases',
      icon: 'fal fa-briefcase-medical',
      label: 'Cases',
    },
    {
      routeLink: 'ambulance',
      icon: 'fal fa-ambulance',
      label: 'Ambulances',
    },
    {
      routeLink: 'hospitals',
      icon: 'fal fa-hospital',
      label: 'Hospitals',
    },
    {
      routeLink: 'settings',
      icon: 'fal fa-cogs',
      label: 'Settings',
    },
  ];

  toggleCollapse(): void {
    this.changeIsLeftSidebarCollapsed.emit(!this.isLeftSidebarCollapsed());
  }

  closeSidenav(): void {
    this.changeIsLeftSidebarCollapsed.emit(true);
  }
}
