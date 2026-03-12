'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    // Add 'staff' to Users role ENUM (IF NOT EXISTS is safe in Postgres)
    await queryInterface.sequelize.query(
      `ALTER TYPE "enum_Users_role" ADD VALUE IF NOT EXISTS 'staff';`
    );
    // Add is_active column for staff enable/disable
    await queryInterface.addColumn('Users', 'is_active', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('Users', 'is_active');
  },
};
