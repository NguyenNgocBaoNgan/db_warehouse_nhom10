package com.example.weather.DAO;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Properties;

public class Connector {

    private String username;
    private String password;

    private String connectionURL;

    public static void main(String[] args) throws SQLException {
        new Connector().getControlConnection();
    }

    public Connector() {
        readConfig();
    }

    private void readConfig() {
        try {
            // Đọc dữ liệu từ file config.txt
            Path path = Paths.get("config.txt");
            Properties properties = new Properties();
            properties.load(Files.newBufferedReader(path));
            // Lưu giá trị vào các biến
            String hostName = properties.getProperty("data.hostName");
            String dbName = properties.getProperty("data.dbName");
            username = properties.getProperty("data.username");
            password = properties.getProperty("data.password");
            connectionURL = "jdbc:mysql://" + hostName + "/" + dbName;
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public Connection getControlConnection() throws SQLException {
        //Tạo đối tượng Connection
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(connectionURL, username, password);
            System.out.println("Kết nối control db thành công");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conn;
    }

    public static Connection getConnection(String hostName, String dbName, String username, String password) throws SQLException {

        //Tạo đối tượng Connection
        Connection conn = null;
        try {
            conn = DriverManager.getConnection("jdbc:mysql://" + hostName + "/" + dbName, username, password);
            System.out.println("Kết nối " + dbName + " db thành công");
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return conn;
    }


    public static void updateFlagDataLinks(Connection conn, String id, String flag) throws SQLException {
        String updateQuery = readFileAsString("updateFlagDataLinks.sql");

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, flag);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật flag " + flag + " bảng data_link thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng data_link được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

    public static void updateFlagConfig(Connection conn, String id, String flag) throws SQLException {
        String updateQuery = readFileAsString("updateFlagConfig.sql");

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, flag);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật flag " + flag + " bảng configuration thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng configuration được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

    }

    public static void updateStatusConfig(Connection conn, String id, String status) throws SQLException {
        String updateQuery = readFileAsString("updateStatusConfig.sql");

        try (PreparedStatement preparedStatement = conn.prepareStatement(updateQuery)) {
            // Thiết lập giá trị tham số cho câu lệnh UPDATE
            preparedStatement.setString(1, status);
            preparedStatement.setString(2, id);

            // Thực hiện cập nhật
            int rowsAffected = preparedStatement.executeUpdate();

            if (rowsAffected > 0) {
                System.out.println("Cập nhật trạng thái " + status + " bảng configuration thành công.");
            } else {
                System.out.println("Không có dòng nào trong bảng configuration được cập nhật.");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
      static String readFileAsString(String filePath)  {
        String data ;
          try {
              data = new String(Files.readAllBytes(Paths.get(filePath)));
          } catch (IOException e) {
              throw new RuntimeException(e);
          }
          return data;
    }
    public static void writeLog(Connection conn, String activityType, String description, String configId, String status, String errorDetail) throws SQLException {
        String insertQuery = "INSERT INTO logs (activity_type, description, config_id, status, error_detail) VALUES (?, ?, ?, ?, ?)";

        try (PreparedStatement preparedStatement = conn.prepareStatement(insertQuery)) {
            preparedStatement.setString(1, activityType);
            preparedStatement.setString(2, description);
            preparedStatement.setString(3, configId);
            preparedStatement.setString(4, status);
            preparedStatement.setString(5, errorDetail);

            int rowsInserted = preparedStatement.executeUpdate();
            if (rowsInserted > 0) {
                System.out.println("Inserted log " + activityType + " " + status + " successfully");
            } else {
                System.out.println("Failed to insert log");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}
